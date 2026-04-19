import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../app_theme.dart';

class TransportControls extends StatelessWidget {
  const TransportControls({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerProvider>();

    return Column(
      children: [
        // ── Transport row ──────────────────────────────────────────────────
        Row(
          children: [
            _TransportBtn(
              label:  'CUE',
              color:  AppTheme.btnCue,
              active: p.transportState == TransportState.cued,
              onTap:  () => p.cue(),
            ),
            const SizedBox(width: 6),
            _TransportBtn(
              label:  'PLAY',
              color:  AppTheme.btnPlay,
              active: p.transportState == TransportState.playing,
              flex:   2,
              onTap:  () => p.play(),
            ),
            const SizedBox(width: 6),
            _TransportBtn(
              label:  'PAUSE',
              color:  AppTheme.btnPause,
              active: p.transportState == TransportState.paused,
              onTap:  () => p.pause(),
            ),
            const SizedBox(width: 6),
            _TransportBtn(
              label:  'STOP',
              color:  AppTheme.btnStop,
              active: p.transportState == TransportState.stopped &&
                      p.currentIndex >= 0,
              onTap:  () => p.stop(),
            ),
            const SizedBox(width: 6),
            _TransportBtn(
              label:  'NEXT ▶',
              color:  AppTheme.btnNext,
              active: false,
              onTap:  () => p.next(),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // ── Mode + Seek row ────────────────────────────────────────────────
        Row(
          children: [
            _ModeBtn(
              label:  'SINGLE',
              active: p.playbackMode == PlaybackMode.single,
              onTap:  () => p.setPlaybackMode(PlaybackMode.single),
            ),
            const SizedBox(width: 6),
            _ModeBtn(
              label:  'CONTINUE',
              active: p.playbackMode == PlaybackMode.continuous,
              onTap:  () => p.setPlaybackMode(PlaybackMode.continuous),
            ),
            const Spacer(),
            _ModeBtn(
              label:  'SEEK',
              active: p.seekEnabled,
              onTap:  () => p.toggleSeek(),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Private button widgets ─────────────────────────────────────────────────

class _TransportBtn extends StatelessWidget {
  final String label;
  final Color  color;
  final bool   active;
  final int    flex;
  final VoidCallback onTap;

  const _TransportBtn({
    required this.label,
    required this.color,
    required this.active,
    required this.onTap,
    this.flex = 1,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = active ? color.withAlpha(220) : color.withAlpha(90);

    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: 52,
          decoration: BoxDecoration(
            color:        bgColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: active ? color : color.withAlpha(60),
              width: active ? 1.5 : 1,
            ),
            boxShadow: active
                ? [BoxShadow(color: color.withAlpha(90), blurRadius: 8)]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color:       active ? Colors.white : Colors.white54,
                fontSize:    13,
                fontWeight:  FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool   active;
  final VoidCallback onTap;

  const _ModeBtn({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding:  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color:        active ? AppTheme.modeActive : AppTheme.modeInactive,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active
                ? const Color(0xFF0099CC)
                : const Color(0xFF444444),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:       active ? Colors.white : AppTheme.textDim,
            fontSize:    12,
            fontWeight:  FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
