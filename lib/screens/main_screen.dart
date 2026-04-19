import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../widgets/waveform_widget.dart';
import '../widgets/vu_meter_widget.dart';
import '../widgets/transport_controls.dart';
import '../widgets/countdown_widget.dart';
import '../widgets/playlist_widget.dart';
import '../app_theme.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<String?> _askFilename(BuildContext context) async {
    final ctrl = TextEditingController(text: 'playlist');
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceHigh,
        title: const Text('Save Playlist',
            style: TextStyle(color: AppTheme.text)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.text),
          decoration: InputDecoration(
            hintText: 'filename (no extension)',
            hintStyle: const TextStyle(color: AppTheme.textDim),
            suffixText: '.xml',
            suffixStyle: const TextStyle(color: AppTheme.textDim),
            filled: true,
            fillColor: AppTheme.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide.none,
            ),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return (result == null || result.isEmpty) ? null : result;
  }

  @override
  Widget build(BuildContext context) {
    // Use keyboard shortcuts for transport
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final p = context.read<PlayerProvider>();
        switch (event.logicalKey) {
          case LogicalKeyboardKey.space:      p.play();
          case LogicalKeyboardKey.keyC:       p.cue();
          case LogicalKeyboardKey.keyN:       p.next();
          case LogicalKeyboardKey.arrowUp:    p.upSelection();
          case LogicalKeyboardKey.arrowDown:  p.downSelection();
          case LogicalKeyboardKey.enter:
          case LogicalKeyboardKey.numpadEnter: p.play();
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: _buildAppBar(context),
        body: LayoutBuilder(
          builder: (context, constraints) {
            // Wide layout (iPad landscape / tablets)
            if (constraints.maxWidth >= 768) {
              return _WideLayout();
            }
            return _NarrowLayout();
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('LIVE PRO PLAYER'),
      actions: [
        // File menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.folder_open, size: 20),
          tooltip: 'File',
          color: AppTheme.surfaceHigh,
          onSelected: (v) async {
            final p = context.read<PlayerProvider>();
            switch (v) {
              case 'add':   await p.addFiles();
              case 'load':  await p.loadPlaylist();
              case 'save':
                final filename = await _askFilename(context);
                if (filename == null || !context.mounted) break;
                try {
                  final path = await p.savePlaylist(filename: filename);
                  if (context.mounted) {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surfaceHigh,
                        title: const Text('Playlist Saved',
                            style: TextStyle(color: AppTheme.text)),
                        content: Text('Saved to:\n$path',
                            style: const TextStyle(
                                color: AppTheme.textDim, fontSize: 13)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppTheme.surfaceHigh,
                        title: const Text('Save Failed',
                            style: TextStyle(color: AppTheme.text)),
                        content: Text('$e',
                            style: const TextStyle(
                                color: AppTheme.textDim, fontSize: 13)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                }
              case 'clear': p.clearPlaylist();
            }
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'add',   child: _MenuItem(Icons.add,             'Add Files…')),
            PopupMenuItem(value: 'load',  child: _MenuItem(Icons.playlist_play,   'Open Playlist…')),
            PopupMenuItem(value: 'save',  child: _MenuItem(Icons.save,            'Save Playlist…')),
            PopupMenuDivider(),
            PopupMenuItem(value: 'clear', child: _MenuItem(Icons.clear_all,       'Clear Playlist')),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.settings, size: 20),
          tooltip: 'Settings',
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

// ── Narrow layout (iPhone / portrait) ─────────────────────────────────────────

class _NarrowLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Player section
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: _PlayerSection(),
        ),

        const Divider(height: 16, color: AppTheme.surfaceHigh),

        // Playlist section — fills remaining space
        const Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: PlaylistWidget(),
          ),
        ),
      ],
    );
  }
}

// ── Wide layout (iPad / landscape) ────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Player panel
        SizedBox(
          width: 420,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: _PlayerSection(),
          ),
        ),
        const VerticalDivider(width: 1, color: AppTheme.surfaceHigh),
        // Playlist panel
        const Expanded(
          child: PlaylistWidget(),
        ),
      ],
    );
  }
}

// ── Player section (shared by both layouts) ────────────────────────────────────

class _PlayerSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerProvider>();
    final track = p.currentTrack;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Track name
        Text(
          track?.displayName ?? '— No track loaded —',
          style: const TextStyle(
            color:      AppTheme.text,
            fontSize:   16,
            fontWeight: FontWeight.w600,
          ),
          maxLines:  1,
          overflow:  TextOverflow.ellipsis,
        ),

        const SizedBox(height: 12),

        // Countdown timers row
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CountdownWidget(
                remaining: p.remaining.isNegative ? Duration.zero : p.remaining,
                fontSize:  48,
                label:     'TRACK',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CountdownWidget(
                remaining: p.playlistRemaining,
                fontSize:  24,
                label:     'PLAYLIST',
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Waveform
        WaveformWidget(
          waveform:    track?.waveform,
          fraction:    p.duration.inMilliseconds > 0
              ? (p.position.inMilliseconds / p.duration.inMilliseconds).clamp(0.0, 1.0)
              : 0.0,
          seekEnabled: p.seekEnabled,
          onSeek:      p.seekToFraction,
        ),

        const SizedBox(height: 8),

        // VU Meter
        VuMeterWidget(left: p.vuLeft, right: p.vuRight),

        const SizedBox(height: 12),

        // Transport controls
        const TransportControls(),

        // Remote indicator
        if (p.remoteEnabled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                    color:  Color(0xFF00DD00),
                    shape:  BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Remote on port ${p.remotePort}',
                  style: const TextStyle(
                      color: AppTheme.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Helper ─────────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String   label;
  const _MenuItem(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 18, color: AppTheme.textDim),
      const SizedBox(width: 10),
      Text(label, style: const TextStyle(color: AppTheme.text, fontSize: 14)),
    ],
  );
}
