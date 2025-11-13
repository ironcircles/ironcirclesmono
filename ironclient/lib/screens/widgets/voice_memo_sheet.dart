import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ironcirclesapp/blocs/voice_input_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/themes/mastertheme.dart';
import 'package:ironcirclesapp/services/voice_memo_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:ironcirclesapp/screens/widgets/voice_waveform.dart';
import 'package:ironcirclesapp/utils/audio_waveform.dart';

enum _VoiceMemoStage { idle, recording, preview }

class VoiceMemoSheet {
  static Future<EncryptedVoiceMemo?> show({
    required BuildContext context,
    required VoiceInputBloc bloc,
  }) {
    return showModalBottomSheet<EncryptedVoiceMemo?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.75),
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return _VoiceMemoSheet(bloc: bloc);
      },
    );
  }
}

class _VoiceMemoSheet extends StatefulWidget {
  final VoiceInputBloc bloc;

  const _VoiceMemoSheet({required this.bloc});

  @override
  State<_VoiceMemoSheet> createState() => _VoiceMemoSheetState();
}

class _VoiceMemoSheetState extends State<_VoiceMemoSheet> {
  final List<double> _recordingWaveform = <double>[];
  List<double> _previewWaveform = <double>[];
  StreamSubscription<VoiceInputState>? _subscription;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  _VoiceMemoStage _stage = _VoiceMemoStage.idle;
  VoiceMemoDraft? _draft;
  bool _isSaving = false;
  bool _hasError = false;
  bool _isPlaying = false;
  Duration _playbackPosition = Duration.zero;
  Duration? _playbackDuration;
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  String? _previewSourcePath;

  static const int _maxWaveformSamples = 1600;
  static const int _storedWaveformSamples = 120;

  @override
  void initState() {
    super.initState();
    _subscription = widget.bloc.stream.listen(_handleBlocState);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    _tearDownPlayer();

    if (_stage == _VoiceMemoStage.recording) {
      widget.bloc.cancelVoiceMemoRecording();
    } else if (_stage == _VoiceMemoStage.preview) {
      widget.bloc.discardVoiceMemoDraft();
    }

    super.dispose();
  }

  void _handleBlocState(VoiceInputState state) {
    if (!mounted) return;

    if (_stage == _VoiceMemoStage.recording) {
      setState(() {
        final level = state.waveformLevel.clamp(0.0, 1.0);
        _recordingWaveform.add(level);
        if (_recordingWaveform.length > _maxWaveformSamples) {
          _recordingWaveform.removeRange(
            0,
            _recordingWaveform.length - _maxWaveformSamples,
          );
        }
        _hasError = false;
      });
    }
  }

  Future<void> _startRecording() async {
    final started = await widget.bloc.startVoiceMemoRecording();
    if (!mounted) return;

    if (started) {
      HapticFeedback.lightImpact();
      _recordingWaveform.clear();
      _previewWaveform = <double>[];
      _draft = null;
      _previewSourcePath = null;
      setState(() {
        _stage = _VoiceMemoStage.recording;
        _elapsed = Duration.zero;
        _hasError = false;
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (!mounted || _stage != _VoiceMemoStage.recording) {
          timer.cancel();
          return;
        }
        setState(() {
          _elapsed += const Duration(milliseconds: 100);
        });
      });
    } else {
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _stopRecording() async {
    final draft = await widget.bloc.stopVoiceMemoRecording();
    if (!mounted) return;
    _timer?.cancel();

    if (draft == null) {
      setState(() {
        _stage = _VoiceMemoStage.idle;
        _recordingWaveform.clear();
        _previewWaveform = <double>[];
        _hasError = true;
      });
      return;
    }

    WaveformResult waveformResult;
    try {
      waveformResult = await loadWaveformFromFile(
        draft.filePath,
        sampleTarget: _storedWaveformSamples,
      );
    } catch (_) {
      waveformResult = const WaveformResult(samples: [], duration: Duration.zero);
    }

    List<double> waveformSnapshot = waveformResult.samples;
    if (waveformSnapshot.isEmpty) {
      waveformSnapshot = _snapshotWaveform();
    }

    final int derivedDurationMs = waveformResult.duration.inMilliseconds;
    final enrichedDraft = draft.copyWith(
      waveform: waveformSnapshot,
      durationMs: derivedDurationMs > 0 ? derivedDurationMs : draft.durationMs,
    );

    setState(() {
      _stage = _VoiceMemoStage.preview;
      _draft = enrichedDraft;
      _previewWaveform = waveformSnapshot;
      _elapsed = Duration(milliseconds: enrichedDraft.durationMs);
      _hasError = false;
      _playbackPosition = Duration.zero;
    });
    await _preparePreviewPlayer(enrichedDraft.filePath);
  }

  Future<void> _restartRecording() async {
    await widget.bloc.discardVoiceMemoDraft();
    if (!mounted) return;
    _recordingWaveform.clear();
    _previewWaveform = <double>[];
    _timer?.cancel();
    await _stopPlayback(resetPosition: true);
    _previewSourcePath = null;
    setState(() {
      _stage = _VoiceMemoStage.idle;
      _elapsed = Duration.zero;
      _draft = null;
      _hasError = false;
    });
    await _startRecording();
  }

  Future<void> _discardDraft() async {
    await widget.bloc.discardVoiceMemoDraft();
    if (!mounted) return;
    _recordingWaveform.clear();
    _previewWaveform = <double>[];
    _timer?.cancel();
    await _stopPlayback(resetPosition: true);
    _previewSourcePath = null;
    setState(() {
      _stage = _VoiceMemoStage.idle;
      _elapsed = Duration.zero;
      _draft = null;
      _hasError = false;
    });
  }

  Future<void> _cancelAndClose() async {
    if (_stage == _VoiceMemoStage.recording) {
      await widget.bloc.cancelVoiceMemoRecording();
    } else if (_stage == _VoiceMemoStage.preview) {
      await widget.bloc.discardVoiceMemoDraft();
    }

    await _stopPlayback();
    _previewSourcePath = null;

    if (!mounted) return;
    Navigator.of(context).pop<EncryptedVoiceMemo?>(null);
  }

  Future<void> _attach() async {
    if (_draft == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _hasError = false;
    });

    try {
      final encrypted = await widget.bloc.finalizeVoiceMemoDraft(
        waveform: List<double>.from(_previewWaveform),
      );
      if (!mounted) return;
      if (encrypted != null) {
        await _stopPlayback();
        Navigator.of(context).pop<EncryptedVoiceMemo?>(encrypted);
      } else {
        setState(() {
          _isSaving = false;
          _hasError = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hasError = true;
      });
    }
  }

  Future<void> _preparePreviewPlayer(String path) async {
    _player ??= AudioPlayer();
    try {
      await _player!.setReleaseMode(ReleaseMode.stop);
      _previewSourcePath = path;
      await _player!.setSource(DeviceFileSource(path));
      final duration = await _player!.getDuration() ??
          Duration(milliseconds: _draft?.durationMs ?? 0);
      if (!mounted) return;
      setState(() {
        _playbackDuration = duration;
        _playbackPosition = Duration.zero;
      });
    } catch (err) {
      debugPrint('VoiceMemoSheet: failed to prepare preview: $err');
      setState(() {
        _hasError = true;
      });
      return;
    }

    _playerStateSub ??= _player!.onPlayerStateChanged.listen((PlayerState state) async {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
      if (state == PlayerState.completed) {
        await _stopPlayback(resetPosition: true);
      }
    });

    _positionSub ??=
        _player!.onPositionChanged.listen((Duration position) {
      if (!mounted) return;
      setState(() {
        _playbackPosition = position;
      });
    });

    _durationSub ??=
        _player!.onDurationChanged.listen((Duration duration) {
      if (!mounted) return;
      setState(() {
        _playbackDuration = duration;
      });
    });
  }

  Future<void> _togglePlayback() async {
    final player = _player;
    if (player == null || _previewSourcePath == null) return;
    try {
      final state = player.state;
      if (state == PlayerState.playing) {
        await player.pause();
      } else if (state == PlayerState.paused) {
        await player.resume();
      } else {
        final duration = _playbackDuration ?? Duration.zero;
        final bool shouldRestart =
            duration > Duration.zero && _playbackPosition >= duration;
        await player.stop();
        if (!shouldRestart && _playbackPosition > Duration.zero) {
          await player.play(
            DeviceFileSource(_previewSourcePath!),
            position: _playbackPosition,
          );
        } else {
          await player.play(DeviceFileSource(_previewSourcePath!));
        }
      }
    } catch (err) {
      debugPrint('VoiceMemoSheet: playback error $err');
      setState(() {
        _hasError = true;
      });
    }
  }

  Future<void> _stopPlayback({bool resetPosition = false}) async {
    final player = _player;
    if (player == null) return;
    try {
      await player.stop();
      if (resetPosition) {
        await player.seek(Duration.zero);
      }
    } catch (err) {
      debugPrint('VoiceMemoSheet: stop playback error $err');
    }
    if (mounted) {
      setState(() {
        _isPlaying = false;
        if (resetPosition) {
          _playbackPosition = Duration.zero;
        }
      });
    }
  }

  void _tearDownPlayer() {
    _playerStateSub?.cancel();
    _playerStateSub = null;
    _positionSub?.cancel();
    _positionSub = null;
    _durationSub?.cancel();
    _durationSub = null;
    _player?.dispose();
    _player = null;
  }

  List<double> _snapshotWaveform() {
    if (_recordingWaveform.isEmpty) {
      return const [];
    }
    if (_recordingWaveform.length <= _storedWaveformSamples) {
      return List<double>.from(_recordingWaveform);
    }

    final List<double> result = <double>[];
    final double bucketSize =
        _recordingWaveform.length / _storedWaveformSamples;
    double start = 0;
    for (int i = 0; i < _storedWaveformSamples; i++) {
      final double end = start + bucketSize;
      int left = start.floor();
      int right = end.ceil();
      if (left >= _recordingWaveform.length) {
        left = _recordingWaveform.length - 1;
      }
      if (right <= left) {
        right = left + 1;
      }
      if (right > _recordingWaveform.length) {
        right = _recordingWaveform.length;
      }

      double maxVal = 0;
      for (int j = left; j < right; j++) {
        maxVal = math.max(maxVal, _recordingWaveform[j]);
      }
      result.add(maxVal);
      start = end;
    }
    return result;
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds % 60;
    final minutes = duration.inMinutes;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = globalState.theme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return WillPopScope(
      onWillPop: () async {
        await _cancelAndClose();
        return false;
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: theme.dialogTransparentBackground,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildHeader(theme),
                const SizedBox(height: 16),
                _buildWaveform(theme),
                const SizedBox(height: 24),
                _buildTimer(theme),
                if (_hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Something went wrong. Please try again.',
                      style: TextStyle(
                        color: theme.bottomHighlightIcon,
                        fontSize: 13,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                _buildControls(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(MasterTheme theme) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 6,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        Icon(
          Icons.graphic_eq,
          size: 72,
          color: theme.bottomHighlightIcon,
        ),
        const SizedBox(height: 12),
        Text(
          'Tap to record your voice',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Voice memos stay encrypted until delivered.',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform(MasterTheme theme) {
    final List<double> samples = switch (_stage) {
      _VoiceMemoStage.recording => List<double>.from(_recordingWaveform),
      _VoiceMemoStage.preview => _previewWaveform,
      _ => const [],
    };

    final double progress =
        (_stage == _VoiceMemoStage.preview && _playbackDuration != null && _playbackDuration!.inMilliseconds > 0)
            ? _playbackPosition.inMilliseconds / _playbackDuration!.inMilliseconds
            : 0.0;

    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: CustomPaint(
        painter: VoiceWaveformPainter(
          samples: samples,
          progress: progress,
          isRecording: _stage == _VoiceMemoStage.recording,
          activeColor: theme.bottomHighlightIcon,
          recordingColor: Colors.redAccent,
          markerColor: Colors.white.withOpacity(0.7),
          targetBarCount: 120,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  Widget _buildTimer(MasterTheme theme) {
    final durationText = _formatDuration(_elapsed);
    final caption = switch (_stage) {
      _VoiceMemoStage.idle => 'Ready to record',
      _VoiceMemoStage.recording => 'Recording…',
      _VoiceMemoStage.preview => _isPlaying ? 'Preview playing…' : 'Preview paused',
    };

    return Column(
      children: [
        Text(
          durationText,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        if (_stage == _VoiceMemoStage.preview && _playbackDuration != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '${_formatDuration(_playbackPosition)} / ${_formatDuration(_playbackDuration!)}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls(MasterTheme theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: switch (_stage) {
        _VoiceMemoStage.idle => [
            _ControlButton(
              icon: Icons.close_rounded,
              label: 'Cancel',
              onTap: _cancelAndClose,
            ),
            _PrimaryButton(
              icon: Icons.mic_rounded,
              label: 'Record',
              onTap: _startRecording,
            ),
            _ControlButton(
              icon: Icons.check_rounded,
              label: 'Attach',
              enabled: false,
            ),
          ],
        _VoiceMemoStage.recording => [
            _ControlButton(
              icon: Icons.refresh_rounded,
              label: 'Restart',
              onTap: _restartRecording,
            ),
            _PrimaryButton(
              icon: Icons.stop_rounded,
              label: 'Stop',
              onTap: _stopRecording,
            ),
            _ControlButton(
              icon: Icons.check_rounded,
              label: 'Attach',
              enabled: false,
            ),
          ],
        _VoiceMemoStage.preview => [
            _ControlButton(
              icon: Icons.delete_outline_rounded,
              label: 'Discard',
              onTap: _discardDraft,
            ),
            _PrimaryButton(
              icon: _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: _isPlaying ? 'Pause' : 'Play',
              onTap: _togglePlayback,
              enabled: !_isSaving && _draft != null,
            ),
            _ControlButton(
              icon: Icons.check_rounded,
              label: _isSaving ? 'Saving…' : 'Attach',
              onTap: _isSaving ? null : _attach,
              busy: _isSaving,
            ),
          ],
      },
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final bool busy;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onTap != null && !busy;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(32),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isEnabled ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: busy
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    icon,
                    color: isEnabled ? Colors.white : Colors.white38,
                    size: 26,
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isEnabled ? Colors.white : Colors.white38,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool enabled;

  const _PrimaryButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onTap != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: isEnabled ? onTap : null,
          borderRadius: BorderRadius.circular(40),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: isEnabled
                  ? LinearGradient(
                      colors: [
                        Colors.redAccent,
                        Colors.orangeAccent,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [
                        Color(0xFF404040),
                        Color(0xFF404040),
                      ],
                    ),
              shape: BoxShape.circle,
              boxShadow: isEnabled
                  ? [
                      BoxShadow(
                        color: Colors.redAccent.withOpacity(0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(isEnabled ? 1.0 : 0.5),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

