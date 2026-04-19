import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/track.dart';
import '../services/audio_service.dart';
import '../services/waveform_service.dart';
import '../services/playlist_service.dart';
import '../services/remote_service.dart';

enum PlaybackMode { single, continuous }
enum TransportState { stopped, playing, paused, cued }

class PlayerProvider extends ChangeNotifier {
  // ── Services ───────────────────────────────────────────────────────────────
  final _audio    = AudioService();
  final _waveform = WaveformService();
  final _playlist = PlaylistService();
  final _remote   = RemoteService();

  // ── State ──────────────────────────────────────────────────────────────────
  List<Track>    tracks          = [];
  int            currentIndex    = -1;
  TransportState transportState  = TransportState.stopped;
  PlaybackMode   playbackMode    = PlaybackMode.single;
  Duration       position        = Duration.zero;
  Duration       duration        = Duration.zero;
  bool           seekEnabled     = false;
  bool           remoteEnabled   = false;
  int            remotePort      = 8000;
  String         deviceIp        = '';

  // VU meter (left/right channels, 0.0–1.0, post-decay)
  double  vuLeft  = 0.0;
  double  vuRight = 0.0;
  double  _vuLeftRaw  = 0.0;
  double  _vuRightRaw = 0.0;

  // ── Subscriptions ──────────────────────────────────────────────────────────
  StreamSubscription<Duration>?      _positionSub;
  StreamSubscription<Duration?>?     _durationSub;
  StreamSubscription<PlayerState>?   _stateSub;
  Timer?                             _vuTimer;

  // ── Init / Dispose ─────────────────────────────────────────────────────────
  PlayerProvider() {
    _init();
  }

  Future<void> _init() async {
    await _audio.init();
    await _loadSettings();
    _subscribeStreams();
    _startVuTimer();
  }

  void _subscribeStreams() {
    _positionSub = _audio.positionStream.listen((pos) {
      position = pos;
      _updateVuFromPosition();
      notifyListeners();
    });

    _durationSub = _audio.durationStream.listen((dur) {
      if (dur != null) {
        duration = dur;
        // Store duration back on track model
        if (currentIndex >= 0 && currentIndex < tracks.length) {
          tracks[currentIndex] = tracks[currentIndex].copyWith(duration: dur);
        }
        notifyListeners();
      }
    });

    _stateSub = _audio.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onTrackCompleted();
      }
      notifyListeners();
    });
  }

  // ── VU Meter ───────────────────────────────────────────────────────────────

  void _startVuTimer() {
    _vuTimer?.cancel();
    _vuTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      _decayVu();
    });
  }

  void _updateVuFromPosition() {
    // kept for position-stream compatibility — real polling is in _decayVu
  }

  void _decayVu() {
    // Poll audio position at 60 Hz directly — don't wait for ~5 Hz position stream
    if (transportState == TransportState.playing) {
      final track = currentTrack;
      if (track != null && duration.inMilliseconds > 0) {
        final currentPos = _audio.position;
        final fraction = (currentPos.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
        if (track.rmsData.isNotEmpty) {
          final (l, r) = _waveform.vuAt(track.rmsData, fraction);
          _vuLeftRaw  = l;
          _vuRightRaw = r;
        } else {
          final t = currentPos.inMilliseconds / 1000.0;
          final base = (sin(t * 2.3) * 0.18 + sin(t * 7.1) * 0.12 +
                        sin(t * 13.7) * 0.06 + 0.42).clamp(0.0, 1.0);
          _vuLeftRaw  = (base + sin(t * 4.1) * 0.04).clamp(0.0, 1.0);
          _vuRightRaw = (base - sin(t * 3.7) * 0.04).clamp(0.0, 1.0);
        }
      }
    }

    const attackRate = 0.8;
    const decayRate  = 0.05;

    final newL = _vuLeftRaw  > vuLeft  ? vuLeft  + (_vuLeftRaw  - vuLeft)  * attackRate
                                       : max(0.0, vuLeft  - decayRate);
    final newR = _vuRightRaw > vuRight ? vuRight + (_vuRightRaw - vuRight) * attackRate
                                       : max(0.0, vuRight - decayRate);

    if ((newL - vuLeft).abs() > 0.005 || (newR - vuRight).abs() > 0.005) {
      vuLeft  = newL;
      vuRight = newR;
      notifyListeners();
    }
  }

  // ── Playlist management ────────────────────────────────────────────────────

  Future<void> addFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'flac', 'aiff', 'aif'],
    );
    if (result == null) return;

    for (final file in result.files) {
      if (file.path != null) {
        tracks.add(Track.fromPath(file.path!));
      }
    }
    notifyListeners();
    _analyzeNewTracks();
  }

  Future<void> loadPlaylist() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xml'],
    );
    if (result?.files.first.path == null) return;
    final loaded = await _playlist.loadPlaylist(result!.files.first.path!);
    tracks = loaded;
    currentIndex = tracks.isEmpty ? -1 : 0;
    notifyListeners();
    _analyzeNewTracks();
  }

  Future<String> savePlaylist({String filename = 'playlist'}) async {
    String? filePath;

    // 1. SAF system picker — user chooses any accessible location
    try {
      filePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save playlist',
        fileName: '$filename.xml',
        allowedExtensions: ['xml'],
      );
    } catch (_) {
      filePath = null;
    }

    // 2. Fallback: Downloads folder
    if (filePath == null && Platform.isAndroid) {
      await Permission.storage.request();
      final downloads = Directory('/storage/emulated/0/Download');
      if (downloads.existsSync()) {
        filePath = '${downloads.path}/$filename.xml';
      }
    }

    // 3. Last resort: app documents directory
    filePath ??= '${(await getApplicationDocumentsDirectory()).path}/$filename.xml';

    await _playlist.savePlaylist(tracks, filePath);
    return filePath;
  }

  void removeTrack(int index) {
    if (index < 0 || index >= tracks.length) return;
    tracks.removeAt(index);
    if (currentIndex >= tracks.length) currentIndex = tracks.length - 1;
    notifyListeners();
  }

  void moveTrack(int from, int to) {
    if (from < 0 || to < 0 || from >= tracks.length || to >= tracks.length) return;
    final track = tracks.removeAt(from);
    tracks.insert(to, track);
    if (currentIndex == from) {
      currentIndex = to;
    } else if (from < currentIndex && to >= currentIndex) {
      currentIndex--;
    } else if (from > currentIndex && to <= currentIndex) {
      currentIndex++;
    }
    notifyListeners();
  }

  void clearPlaylist() {
    _audio.stop();
    tracks.clear();
    currentIndex   = -1;
    transportState = TransportState.stopped;
    position       = Duration.zero;
    duration       = Duration.zero;
    notifyListeners();
  }

  // ── Waveform analysis ──────────────────────────────────────────────────────

  void _analyzeNewTracks() {
    for (int i = 0; i < tracks.length; i++) {
      if (tracks[i].status == TrackStatus.pending) {
        _analyzeTrack(i);
      }
    }
  }

  Future<void> _analyzeTrack(int index) async {
    if (index < 0 || index >= tracks.length) return;
    tracks[index] = tracks[index].copyWith(status: TrackStatus.loading);
    notifyListeners();

    final updated = await _waveform.analyzeTrack(tracks[index]);
    if (index < tracks.length) {
      tracks[index] = updated;
      notifyListeners();
    }
  }

  // ── Transport commands ─────────────────────────────────────────────────────

  Future<void> play() async {
    if (tracks.isEmpty) return;

    if (currentIndex < 0) {
      await selectTrack(0, autoPlay: true);
      return;
    }

    transportState = TransportState.playing;
    notifyListeners();
    unawaited(_audio.play());
  }

  Future<void> pause() async {
    await _audio.pause();
    transportState = TransportState.paused;
    _vuLeftRaw  = 0;
    _vuRightRaw = 0;
    notifyListeners();
  }

  Future<void> stop() async {
    await _audio.stop();
    transportState = TransportState.stopped;
    position       = Duration.zero;
    _vuLeftRaw     = 0;
    _vuRightRaw    = 0;
    notifyListeners();
  }

  Future<void> cue() async {
    await _audio.cue();
    transportState = TransportState.cued;
    position       = Duration.zero;
    _vuLeftRaw     = 0;
    _vuRightRaw    = 0;
    notifyListeners();
  }

  Future<void> next() async {
    if (tracks.isEmpty) return;
    final nextIndex = currentIndex + 1;
    if (nextIndex >= tracks.length) {
      await stop();
      return;
    }
    await selectTrack(nextIndex);
    if (transportState == TransportState.playing ||
        playbackMode   == PlaybackMode.continuous) {
      await play();
    }
  }

  Future<void> previous() async {
    if (tracks.isEmpty) return;
    final prevIndex = currentIndex - 1;
    if (prevIndex < 0) return;
    await selectTrack(prevIndex);
  }

  Future<void> upSelection() async {
    if (currentIndex > 0) await selectTrack(currentIndex - 1);
  }

  Future<void> downSelection() async {
    if (currentIndex < tracks.length - 1) await selectTrack(currentIndex + 1);
  }

  Future<void> selectTrack(int index, {bool autoPlay = false}) async {
    if (index < 0 || index >= tracks.length) return;

    final wasPlaying = transportState == TransportState.playing;
    await _audio.stop();

    currentIndex   = index;
    transportState = TransportState.stopped;
    position       = Duration.zero;
    duration       = Duration.zero;
    _vuLeftRaw     = 0;
    _vuRightRaw    = 0;
    notifyListeners();

    final dur = await _audio.loadFile(tracks[index].path);
    if (dur != null) {
      duration = dur;
      tracks[index] = tracks[index].copyWith(duration: dur);
    }

    // Trigger analysis if not yet done
    if (tracks[index].status == TrackStatus.pending) {
      _analyzeTrack(index);
    }

    if (autoPlay || wasPlaying) {
      transportState = TransportState.playing;
      unawaited(_audio.play());
    }

    notifyListeners();
  }

  Future<void> seekToFraction(double fraction) async {
    if (!seekEnabled) return;
    await _audio.seekFraction(fraction);
  }

  void _onTrackCompleted() {
    if (playbackMode == PlaybackMode.continuous) {
      next();
    } else {
      transportState = TransportState.stopped;
      position       = Duration.zero;
      _vuLeftRaw     = 0;
      _vuRightRaw    = 0;
      notifyListeners();
    }
  }

  // ── Remote control ─────────────────────────────────────────────────────────

  Future<void> toggleRemote() async {
    if (_remote.isRunning) {
      await _remote.stop();
      remoteEnabled = false;
    } else {
      final ok = await _remote.start(_handleRemoteCommand);
      remoteEnabled = ok;
      if (ok) await _fetchDeviceIp();
    }
    await _saveSettings();
    notifyListeners();
  }

  Future<void> setRemotePort(int port) async {
    remotePort = port;
    if (_remote.isRunning) {
      await _remote.stop();
      await _remote.changePort(port);
      await _remote.start(_handleRemoteCommand);
    } else {
      await _remote.changePort(port);
    }
    await _saveSettings();
    notifyListeners();
  }

  void _handleRemoteCommand(String cmd) {
    switch (cmd) {
      case 'play':     unawaited(play());
      case 'pause':    unawaited(pause());
      case 'stop':     unawaited(stop());
      case 'next':     unawaited(next());
      case 'previous': unawaited(previous());
      case 'cue':      unawaited(cue());
      case 'up':       unawaited(upSelection());
      case 'down':     unawaited(downSelection());
    }
  }

  Future<void> _fetchDeviceIp() async {
    try {
      for (final iface in await NetworkInterface.list()) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback && addr.type == InternetAddressType.IPv4) {
            deviceIp = addr.address;
            notifyListeners();
            return;
          }
        }
      }
    } catch (_) {}
  }

  // ── Mode ───────────────────────────────────────────────────────────────────

  void setPlaybackMode(PlaybackMode mode) {
    playbackMode = mode;
    notifyListeners();
  }

  void toggleSeek() {
    seekEnabled = !seekEnabled;
    notifyListeners();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remoteEnabled', remoteEnabled);
    await prefs.setInt('remotePort',     remotePort);
    await prefs.setString('playbackMode',
        playbackMode == PlaybackMode.continuous ? 'continuous' : 'single');
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    remoteEnabled = prefs.getBool('remoteEnabled') ?? false;
    remotePort    = prefs.getInt('remotePort') ?? 8000;
    playbackMode  = (prefs.getString('playbackMode') == 'continuous')
        ? PlaybackMode.continuous
        : PlaybackMode.single;

    if (remoteEnabled) {
      await _remote.changePort(remotePort);
      await _remote.start(_handleRemoteCommand);
      await _fetchDeviceIp();
    }

    notifyListeners();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  Track? get currentTrack =>
      currentIndex >= 0 && currentIndex < tracks.length
          ? tracks[currentIndex]
          : null;

  Duration get remaining => duration - position;

  Duration get playlistRemaining {
    if (tracks.isEmpty || currentIndex < 0) return Duration.zero;
    var total = remaining;
    for (int i = currentIndex + 1; i < tracks.length; i++) {
      total += tracks[i].duration;
    }
    return total;
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _vuTimer?.cancel();
    _audio.dispose();
    _remote.stop();
    super.dispose();
  }
}
