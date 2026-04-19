import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/track.dart';

/// Extracts waveform data from audio files and pre-computes RMS buckets
/// for the VU meter simulation during playback.
class WaveformService {
  Directory? _cacheDir;

  Future<Directory> get cacheDir async {
    _cacheDir ??= Directory(
      p.join((await getApplicationSupportDirectory()).path, 'waveform_cache'),
    )..createSync(recursive: true);
    return _cacheDir!;
  }

  // ── Waveform extraction ────────────────────────────────────────────────────

  /// Extract waveform for [track] and return an updated copy.
  /// Caches results to disk keyed by file path hash.
  Future<Track> analyzeTrack(Track track) async {
    final dir   = await cacheDir;
    final hash  = track.path.hashCode.toRadixString(16);
    final outFile = File(p.join(dir.path, '$hash.wave'));

    try {
      Waveform? waveform;

      await for (final progress in JustWaveform.extract(
        audioInFile: File(track.path),
        waveOutFile: outFile,
        zoom: const WaveformZoom.pixelsPerSecond(100),
      )) {
        if (progress.waveform != null) {
          waveform = progress.waveform;
        }
      }

      if (waveform == null) return track.copyWith(status: TrackStatus.error);

      // 10 buckets/second → ~100 ms resolution for a responsive VU meter
      final numBuckets = (waveform.length / 10).round().clamp(500, 12000);
      final rms = _computeRMSBuckets(waveform, numBuckets);

      return track.copyWith(
        waveform: waveform,
        rmsData:  rms,
        status:   TrackStatus.ready,
      );
    } catch (e) {
      debugPrint('WaveformService: analysis failed for ${track.path}: $e');
      return track.copyWith(status: TrackStatus.error);
    }
  }

  // ── RMS computation ────────────────────────────────────────────────────────

  /// Divide waveform into [numBuckets] time segments.
  /// Returns normalised RMS values [0.0–1.0] for VU meter display.
  List<double> _computeRMSBuckets(Waveform waveform, int numBuckets) {
    final length = waveform.length;
    if (length == 0) return List.filled(numBuckets, 0.0);

    final buckets = List<double>.filled(numBuckets, 0.0);
    // flags bit 0: 0 = 16-bit (Int16List, -32768..32767), 1 = 8-bit (Int8List, -128..127)
    final scale = (waveform.flags & 1) == 0 ? 32768.0 : 128.0;

    for (int b = 0; b < numBuckets; b++) {
      final start = (b / numBuckets * length).floor();
      final end   = ((b + 1) / numBuckets * length).ceil().clamp(0, length);

      double sumSq = 0;
      int    count = 0;
      for (int i = start; i < end; i++) {
        final minVal  = waveform.getPixelMin(i) / scale;
        final maxVal  = waveform.getPixelMax(i) / scale;
        final amplitude = (maxVal - minVal) / 2.0;
        sumSq += amplitude * amplitude;
        count++;
      }
      buckets[b] = count > 0 ? sqrt(sumSq / count).clamp(0.0, 1.0) : 0.0;
    }

    return buckets;
  }

  /// Get the RMS value at a given playback [fraction] (0.0–1.0).
  /// Adds slight L/R variation to simulate a real stereo meter.
  (double left, double right) vuAt(List<double> rmsData, double fraction) {
    if (rmsData.isEmpty) return (0.0, 0.0);
    final idx  = (fraction * (rmsData.length - 1)).round().clamp(0, rmsData.length - 1);
    // 2.5× gain so typical music fills the meter properly
    final base = (rmsData[idx] * 2.5).clamp(0.0, 1.0);
    final seed = idx * 1234;
    final spread = ((seed % 7) / 100.0);
    return (
      (base + spread).clamp(0.0, 1.0),
      (base - spread).clamp(0.0, 1.0),
    );
  }
}
