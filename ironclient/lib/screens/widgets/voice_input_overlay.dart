import 'package:flutter/material.dart';
import 'package:ironcirclesapp/blocs/voice_input_bloc.dart';

class VoiceInputOverlay extends StatelessWidget {
  final VoiceInputBloc bloc;
  final VoidCallback onStopVoiceToText;
  final VoidCallback onStopVoiceMemo;

  const VoiceInputOverlay({
    super.key,
    required this.bloc,
    required this.onStopVoiceToText,
    required this.onStopVoiceMemo,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<VoiceInputState>(
      stream: bloc.stream,
      initialData: bloc.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? VoiceInputState.initial;
        if (!state.memoRecording && !state.voiceToTextActive) {
          return const SizedBox.shrink();
        }

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (state.memoRecording)
                  Row(
                    children: [
                      const Icon(Icons.mic, color: Colors.redAccent),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Recording voice memo…',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: onStopVoiceMemo,
                        child: const Text('Stop'),
                      ),
                    ],
                  ),
                if (state.voiceToTextActive)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.graphic_eq, color: Colors.lightBlueAccent),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Voice to text…',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            if (state.partialText.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  state.partialText,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: onStopVoiceToText,
                        child: const Text('Done'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
