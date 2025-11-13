import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

class WaveformResult {
  final List<double> samples;
  final Duration duration;

  const WaveformResult({
    required this.samples,
    required this.duration,
  });
}

Future<WaveformResult> loadWaveformFromFile(
  String path, {
  int sampleTarget = 120,
}) async {
  final file = File(path);
  if (!await file.exists()) {
    return const WaveformResult(samples: [], duration: Duration.zero);
  }

  late Uint8List bytes;
  try {
    bytes = await file.readAsBytes();
  } catch (_) {
    return const WaveformResult(samples: [], duration: Duration.zero);
  }

  if (bytes.length < 44) {
    return const WaveformResult(samples: [], duration: Duration.zero);
  }

  int channels = _readUint16LE(bytes, 22);
  final int sampleRate = _readUint32LE(bytes, 24);
  final int byteRate = _readUint32LE(bytes, 28);
  final int bitsPerSample = _readUint16LE(bytes, 34);
  final int bytesPerSample = (bitsPerSample ~/ 8).clamp(1, 4);
  if (channels <= 0) {
    channels = 1;
  }

  int offset = 12;
  int dataStart = -1;
  int dataLength = 0;
  while (offset + 8 <= bytes.length) {
    final String chunkId = String.fromCharCodes(
      bytes.sublist(offset, offset + 4),
    );
    final int chunkSize = _readUint32LE(bytes, offset + 4);
    offset += 8;
    if (chunkId.trim() == 'data') {
      dataStart = offset;
      dataLength = math.min(chunkSize, bytes.length - offset);
      break;
    }
    offset += chunkSize;
  }

  if (dataStart == -1 || dataLength <= 0) {
    dataStart = 44;
    dataLength = bytes.length - dataStart;
    if (dataLength <= 0) {
      return const WaveformResult(samples: [], duration: Duration.zero);
    }
  }

  final int frameSize = bytesPerSample * channels;
  if (frameSize <= 0) {
    return const WaveformResult(samples: [], duration: Duration.zero);
  }

  final int frameCount = dataLength ~/ frameSize;
  if (frameCount <= 0) {
    return const WaveformResult(samples: [], duration: Duration.zero);
  }

  final int bucketCount = math.max(1, math.min(sampleTarget, frameCount));
  final double framesPerBucket = frameCount / bucketCount;

  final List<double> peaks = <double>[];
  double bucketPeak = 0.0;
  double maxPeak = 0.0;
  int currentBucket = 0;

  for (int frame = 0; frame < frameCount; frame++) {
    double framePeak = 0.0;
    final int frameOffset = dataStart + (frame * frameSize);
    for (int channel = 0; channel < channels; channel++) {
      final int sampleOffset = frameOffset + (channel * bytesPerSample);
      if (sampleOffset + 1 >= bytes.length) {
        break;
      }
      final int sample = _readIntSample(
        bytes,
        sampleOffset,
        bytesPerSample,
      );
      final double normalized = (sample.abs()) / _sampleMaxValue(bytesPerSample);
      framePeak = math.max(framePeak, normalized);
    }

    bucketPeak = math.max(bucketPeak, framePeak);

    final double threshold = (currentBucket + 1) * framesPerBucket;
    if (frame + 1 >= threshold || frame == frameCount - 1) {
      peaks.add(bucketPeak);
      maxPeak = math.max(maxPeak, bucketPeak);
      bucketPeak = 0.0;
      currentBucket++;
    }
  }

  List<double> normalizedPeaks;
  if (maxPeak > 0) {
    const double minDb = -50.0;
    normalizedPeaks = peaks
        .map((value) {
          final double clamped = value.clamp(1e-6, 1.0);
          final double db = 20 * math.log(clamped) / math.ln10;
          final double scaled = (db - minDb) / -minDb;
          return scaled.clamp(0.0, 1.0);
        })
        .toList(growable: false);
  } else {
    normalizedPeaks = List<double>.filled(peaks.length, 0.0, growable: false);
  }

  Duration duration;
  if (byteRate > 0) {
    duration = Duration(milliseconds: ((dataLength * 1000) ~/ byteRate));
  } else if (sampleRate > 0) {
    duration = Duration(milliseconds: ((frameCount * 1000) ~/ sampleRate));
  } else {
    duration = Duration.zero;
  }

  return WaveformResult(samples: normalizedPeaks, duration: duration);
}

int _readUint32LE(Uint8List bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

int _readUint16LE(Uint8List bytes, int offset) {
  return bytes[offset] | (bytes[offset + 1] << 8);
}

int _readIntSample(Uint8List bytes, int offset, int bytesPerSample) {
  switch (bytesPerSample) {
    case 1:
      return bytes[offset] - 128;
    case 2:
      final int value = bytes[offset] | (bytes[offset + 1] << 8);
      return value >= 0x8000 ? value - 0x10000 : value;
    default:
      int value = 0;
      for (int i = 0; i < bytesPerSample; i++) {
        value |= bytes[offset + i] << (8 * i);
      }
      final int signBit = 1 << (bytesPerSample * 8 - 1);
      if ((value & signBit) != 0) {
        value -= (1 << (bytesPerSample * 8));
      }
      return value;
  }
}

double _sampleMaxValue(int bytesPerSample) {
  switch (bytesPerSample) {
    case 1:
      return 128.0;
    case 2:
      return 32768.0;
    default:
      return math.pow(2, (bytesPerSample * 8) - 1).toDouble();
  }
}

