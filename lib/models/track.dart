import 'package:just_waveform/just_waveform.dart';

enum TrackStatus { pending, loading, ready, error }

class Track {
  final String path;
  final String displayName;
  Duration duration;
  Waveform? waveform;
  List<double> rmsData;   // Pre-computed RMS buckets for VU meter
  TrackStatus status;

  Track({
    required this.path,
    required this.displayName,
    this.duration   = Duration.zero,
    this.waveform,
    List<double>? rmsData,
    this.status     = TrackStatus.pending,
  }) : rmsData = rmsData ?? [];

  factory Track.fromPath(String path) {
    final fileName = path.split('/').last;
    final name = fileName.replaceAll(
      RegExp(r'\.(wav|mp3|flac|aiff?)$', caseSensitive: false),
      '',
    );
    return Track(path: path, displayName: name);
  }

  String get durationString => _formatDuration(duration);

  static String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h.toString().padLeft(2,'0')}:$m:$s' : '$m:$s';
  }

  Track copyWith({
    Duration? duration,
    Waveform? waveform,
    List<double>? rmsData,
    TrackStatus? status,
  }) => Track(
    path:        path,
    displayName: displayName,
    duration:    duration  ?? this.duration,
    waveform:    waveform  ?? this.waveform,
    rmsData:     rmsData   ?? this.rmsData,
    status:      status    ?? this.status,
  );
}
