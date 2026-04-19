import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../models/track.dart';
import '../app_theme.dart';

class PlaylistWidget extends StatelessWidget {
  const PlaylistWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerProvider>();

    if (p.tracks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_music, size: 48, color: AppTheme.inactive),
            SizedBox(height: 12),
            Text('Playlist empty',
                style: TextStyle(color: AppTheme.textDim, fontSize: 14)),
            SizedBox(height: 4),
            Text('Use File → Add Files to load audio',
                style: TextStyle(color: AppTheme.textDisabled, fontSize: 12)),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      itemCount: p.tracks.length,
      onReorder: (from, to) {
        if (to > from) to -= 1;
        p.moveTrack(from, to);
      },
      itemBuilder: (context, index) {
        final track   = p.tracks[index];
        final isCurrent = index == p.currentIndex;
        final isPlaying = isCurrent && p.transportState == TransportState.playing;

        return _TrackRow(
          key:       ValueKey(track.path + index.toString()),
          track:     track,
          index:     index,
          isCurrent: isCurrent,
          isPlaying: isPlaying,
          onTap:     () => p.selectTrack(index),
          onDoubleTap: () {
            p.selectTrack(index);
            p.play();
          },
          onDelete:  () => p.removeTrack(index),
        );
      },
    );
  }
}

class _TrackRow extends StatelessWidget {
  final Track    track;
  final int      index;
  final bool     isCurrent;
  final bool     isPlaying;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;
  final VoidCallback onDelete;

  const _TrackRow({
    super.key,
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.isPlaying,
    required this.onTap,
    required this.onDoubleTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isPlaying  ? AppTheme.rowPlaying
             : isCurrent  ? AppTheme.rowSelected
             : Colors.transparent;

    return GestureDetector(
      onTap:       onTap,
      onDoubleTap: onDoubleTap,
      child: Container(
        color:  bg,
        height: 44,
        child: Row(
          children: [
            // ── Index ────────────────────────────────────────────────────
            SizedBox(
              width: 38,
              child: Center(
                child: isPlaying
                    ? const Icon(Icons.volume_up,
                        size: 16, color: AppTheme.vuGreen)
                    : Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrent ? AppTheme.text : AppTheme.textDim,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),

            // ── Status dot ───────────────────────────────────────────────
            SizedBox(
              width: 10,
              child: track.status == TrackStatus.loading
                  ? const SizedBox(
                      width: 8, height: 8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppTheme.textDim,
                      ))
                  : track.status == TrackStatus.error
                      ? const Icon(Icons.error_outline,
                          size: 10, color: AppTheme.btnStop)
                      : const SizedBox.shrink(),
            ),

            const SizedBox(width: 6),

            // ── Name ─────────────────────────────────────────────────────
            Expanded(
              child: Text(
                track.displayName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:      isCurrent ? AppTheme.text : AppTheme.textDim,
                  fontSize:   14,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),

            // ── Duration ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                track.durationString,
                style: const TextStyle(
                  color:    AppTheme.textDim,
                  fontSize: 12,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),

            // ── Drag handle ──────────────────────────────────────────────
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.drag_handle,
                    size: 18, color: AppTheme.textDisabled),
              ),
            ),

            // ── Delete ────────────────────────────────────────────────────
            GestureDetector(
              onTap: onDelete,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.close, size: 16, color: AppTheme.textDim),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
