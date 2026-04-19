import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

/// Wraps just_audio with the transport commands needed by Live Pro Player.
class AudioService {
  final AudioPlayer _player = AudioPlayer();

  // ── Streams ────────────────────────────────────────────────────────────────
  Stream<Duration>       get positionStream    => _player.positionStream;
  Stream<Duration?>      get durationStream    => _player.durationStream;
  Stream<PlayerState>    get playerStateStream => _player.playerStateStream;
  Stream<ProcessingState> get processingStream => _player.processingStateStream;

  // ── Getters ────────────────────────────────────────────────────────────────
  Duration? get duration  => _player.duration;
  Duration  get position  => _player.position;
  bool      get isPlaying => _player.playing;

  // ── Initialisation ─────────────────────────────────────────────────────────
  Future<void> init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
    ));

    // Handle audio interruptions (phone calls, other apps)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        if (isPlaying) _player.pause();
      } else {
        if (event.type == AudioInterruptionType.pause) _player.play();
      }
    });
  }

  // ── Transport ──────────────────────────────────────────────────────────────
  Future<Duration?> loadFile(String path) async {
    try {
      return await _player.setFilePath(path);
    } catch (e) {
      return null;
    }
  }

  Future<void> play()  => _player.play();
  Future<void> pause() => _player.pause();

  Future<void> stop() async {
    await _player.stop();
    await _player.seek(Duration.zero);
  }

  /// Cue: rewind to zero without playing (or rewind while paused).
  Future<void> cue() async {
    await _player.pause();
    await _player.seek(Duration.zero);
  }

  Future<void> seek(Duration position) => _player.seek(position);

  /// Seek to a fractional position [0.0–1.0].
  Future<void> seekFraction(double fraction) async {
    final d = _player.duration;
    if (d == null) return;
    await _player.seek(d * fraction);
  }

  // ── Cleanup ────────────────────────────────────────────────────────────────
  Future<void> dispose() => _player.dispose();
}
