import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/screens/widgets/voice_waveform.dart';
import 'package:ironcirclesapp/services/cache/filecache_service.dart';
import 'package:ironcirclesapp/utils/audio_waveform.dart';
import 'package:ironcirclesapp/models/globalstate.dart';

class VoiceMemoMessageBubble extends StatefulWidget {
  final CircleObject circleObject;
  final String circlePath;
  final bool isUser;
  final double maxWidth;
  final Color textColor;

  const VoiceMemoMessageBubble({
    super.key,
    required this.circleObject,
    required this.circlePath,
    required this.isUser,
    required this.maxWidth,
    required this.textColor,
  });

  @override
  State<VoiceMemoMessageBubble> createState() => _VoiceMemoMessageBubbleState();
}

class _VoiceMemoMessageBubbleState extends State<VoiceMemoMessageBubble> {
  static final Map<String, WaveformResult> _waveformCache =
      <String, WaveformResult>{};

  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  List<double> _waveform = const [];
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _filePath;
  bool _isPlaying = false;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _initialise();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _initialise() async {
    final String? path = await _resolveLocalPath();
    if (!mounted) return;
    if (path == null) {
      setState(() {
        _loading = false;
        _error = true;
      });
      return;
    }

    _filePath = path;

    WaveformResult waveformResult;
    try {
      waveformResult = _waveformCache[path] ??
          await loadWaveformFromFile(path, sampleTarget: 140);
      _waveformCache[path] = waveformResult;
    } catch (_) {
      waveformResult = const WaveformResult(samples: [], duration: Duration.zero);
    }

    if (!mounted) return;

    final List<double> samples = waveformResult.samples.isNotEmpty
        ? waveformResult.samples
        : List<double>.filled(140, 0.0, growable: false);

    final Duration computedDuration = waveformResult.duration;

    _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _playerStateSub = _player!.onPlayerStateChanged.listen((PlayerState state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
      if (state == PlayerState.completed) {
        _stop(resetPosition: true);
      }
    });

    _positionSub = _player!.onPositionChanged.listen((Duration position) {
      if (!mounted) return;
      setState(() {
        _position = position;
      });
    });

    _durationSub = _player!.onDurationChanged.listen((Duration duration) {
      if (!mounted) return;
      if (duration == Duration.zero) {
        return;
      }
      setState(() {
        _duration = duration;
      });
    });

    setState(() {
      _waveform = samples;
      if (computedDuration > Duration.zero) {
        _duration = computedDuration;
      }
      _loading = false;
      _error = false;
    });
  }

  Future<String?> _resolveLocalPath() async {
    try {
      final File? existing = widget.circleObject.file?.actualFile;
      if (existing != null && await existing.exists()) {
        return existing.path;
      }
      if (widget.circlePath.isEmpty ||
          widget.circleObject.seed == null ||
          widget.circleObject.file?.extension == null) {
        return null;
      }
      final String fileName = _composeFileName(
        widget.circleObject.seed!,
        widget.circleObject.file!.extension,
      );
      final String path =
          FileCacheService.returnFilePath(widget.circlePath, fileName);
      final file = File(path);
      if (await file.exists()) {
        return file.path;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  String _composeFileName(String seed, String? extension) {
    if (extension == null || extension.isEmpty) {
      return seed;
    }
    return extension.startsWith('.') ? '$seed$extension' : '$seed.$extension';
  }

  Future<void> _togglePlayback() async {
    if (_player == null || _filePath == null) return;
    try {
      final PlayerState state = _player!.state;
      if (state == PlayerState.playing) {
        await _player!.pause();
      } else if (state == PlayerState.paused) {
        await _player!.resume();
      } else {
        final bool shouldRestart =
            _duration > Duration.zero && _position >= _duration;
        await _player!.stop();
        if (!shouldRestart && _position > Duration.zero) {
          await _player!
              .play(DeviceFileSource(_filePath!), position: _position);
        } else {
          await _player!.play(DeviceFileSource(_filePath!));
        }
      }
    } catch (err) {
      debugPrint('VoiceMemoMessageBubble playback error: $err');
      if (!mounted) return;
      setState(() {
        _error = true;
      });
    }
  }

  Future<void> _stop({bool resetPosition = false}) async {
    if (_player == null) return;
    try {
      await _player!.stop();
      if (resetPosition) {
        await _player!.seek(Duration.zero);
      }
    } catch (err) {
      debugPrint('VoiceMemoMessageBubble stop error: $err');
    }
    if (!mounted) return;
    setState(() {
      _isPlaying = false;
      if (resetPosition) {
        _position = Duration.zero;
      }
    });
  }

  String _formatDuration(Duration duration) {
    final int minutes = duration.inMinutes;
    final int seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: widget.isUser
                ? globalState.theme.userObjectBackground
                : globalState.theme.memberObjectBackground,
            borderRadius: BorderRadius.circular(24),
          ),
          alignment: Alignment.center,
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              valueColor: AlwaysStoppedAnimation<Color>(
                globalState.theme.bottomHighlightIcon,
              ),
            ),
          ),
        ),
      );
    }

    if (_error || _filePath == null) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.maxWidth,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: widget.isUser
                ? globalState.theme.userObjectBackground
                : globalState.theme.memberObjectBackground,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Voice memo unavailable',
            style: TextStyle(
              color: widget.textColor,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    final double progress = (_duration.inMilliseconds > 0)
        ? (_position.inMilliseconds / _duration.inMilliseconds)
            .clamp(0.0, 1.0)
        : 0.0;

    final Color accent = globalState.theme.bottomHighlightIcon;
    final Color bubbleColor = widget.isUser
        ? globalState.theme.userObjectBackground
        : globalState.theme.memberObjectBackground;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _togglePlayback,
      child: Container(
        constraints: BoxConstraints(
          minWidth: 200,
          maxWidth: widget.maxWidth,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accent,
                    accent.withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.black87,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: SizedBox(
                height: 56,
                child: CustomPaint(
                  painter: VoiceWaveformPainter(
                    samples: _waveform,
                    progress: progress,
                    isRecording: false,
                    activeColor: accent,
                    recordingColor: accent,
                    markerColor: Colors.white.withOpacity(0.8),
                    targetBarCount: 140,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              _formatDuration(
                  _duration == Duration.zero ? _position : _duration),
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

