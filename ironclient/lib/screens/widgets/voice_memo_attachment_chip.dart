import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/services/voice_memo_service.dart';

import 'voice_waveform.dart';

class VoiceMemoAttachmentChip extends StatefulWidget {
  final EncryptedVoiceMemo memo;

  const VoiceMemoAttachmentChip({
    super.key,
    required this.memo,
  });

  @override
  State<VoiceMemoAttachmentChip> createState() =>
      _VoiceMemoAttachmentChipState();
}

class _VoiceMemoAttachmentChipState extends State<VoiceMemoAttachmentChip> {
  late final AudioPlayer _player;
  StreamSubscription<PlayerState>? _stateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
    _duration = Duration(milliseconds: widget.memo.durationMs);

    _stateSub = _player.onPlayerStateChanged.listen((PlayerState state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state == PlayerState.playing;
        if (state == PlayerState.completed) {
          _position = Duration.zero;
        }
      });
    });

    _positionSub = _player.onPositionChanged.listen((Duration position) {
      if (!mounted) return;
      setState(() {
        _position = position;
      });
    });

    _durationSub = _player.onDurationChanged.listen((Duration duration) {
      if (!mounted) return;
      if (duration > Duration.zero) {
        setState(() {
          _duration = duration;
        });
      }
    });
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    try {
      final state = _player.state;
      if (state == PlayerState.playing) {
        await _player.pause();
      } else if (state == PlayerState.paused) {
        await _player.resume();
      } else {
        final Duration total =
            _duration > Duration.zero ? _duration : Duration(milliseconds: widget.memo.durationMs);
        final bool shouldRestart =
            total > Duration.zero && _position >= total;
        final Duration startPosition =
            shouldRestart ? Duration.zero : _position;
        await _player.play(
          BytesSource(
            widget.memo.previewBytes,
            mimeType: 'audio/wav',
          ),
          position: startPosition,
        );
      }
    } catch (err) {
      debugPrint('VoiceMemoAttachmentChip playback error: $err');
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = globalState.theme;
    final Duration total =
        _duration > Duration.zero ? _duration : Duration(milliseconds: widget.memo.durationMs);
    final double progress = total.inMilliseconds > 0
        ? (_position.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final Color accent = theme.bottomHighlightIcon;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _togglePlayback,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          constraints: const BoxConstraints(minWidth: 200, maxWidth: 280),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: theme.memberObjectBackground,
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
                      color: accent.withOpacity(0.2),
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
                      samples: widget.memo.waveform,
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
                _formatDuration(total),
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

