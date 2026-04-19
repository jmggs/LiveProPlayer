import 'package:flutter/material.dart';
import 'package:just_waveform/just_waveform.dart';
import '../app_theme.dart';

/// Displays the audio waveform with a position cursor.
/// Tappable when seekEnabled is true.
class WaveformWidget extends StatelessWidget {
  final Waveform? waveform;
  final double    fraction;       // 0.0–1.0 playback position
  final bool      seekEnabled;
  final ValueChanged<double>? onSeek; // returns fraction 0.0–1.0

  const WaveformWidget({
    super.key,
    this.waveform,
    required this.fraction,
    this.seekEnabled = false,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: seekEnabled ? (details) {
        final box = context.findRenderObject() as RenderBox;
        final f   = (details.localPosition.dx / box.size.width).clamp(0.0, 1.0);
        onSeek?.call(f);
      } : null,
      child: Container(
        height:     80,
        decoration: BoxDecoration(
          color:        AppTheme.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: CustomPaint(
            painter: _WaveformPainter(
              waveform: waveform,
              fraction: fraction,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Waveform? waveform;
  final double    fraction;

  const _WaveformPainter({this.waveform, required this.fraction});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final mid = h / 2;

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = AppTheme.surface);

    if (waveform == null) {
      // Loading placeholder — animated bars
      _drawPlaceholder(canvas, size);
      return;
    }

    final playedPaint   = Paint()..color = AppTheme.waveformPlayed;
    final unplayedPaint = Paint()..color = AppTheme.waveformUnplayed;
    final cursorPaint   = Paint()
      ..color       = AppTheme.waveformCursor
      ..strokeWidth = 1.5;

    final pixelWidth = w / waveform!.length;
    final cursorX    = w * fraction;

    for (int i = 0; i < waveform!.length; i++) {
      final x     = i * pixelWidth;
      final paint = x <= cursorX ? playedPaint : unplayedPaint;

      // Normalise sample to canvas height
      final minSample = waveform!.getPixelMin(i) / 32768.0;
      final maxSample = waveform!.getPixelMax(i) / 32768.0;

      final top    = (mid - maxSample * mid).clamp(0.0, h);
      final bottom = (mid - minSample * mid).clamp(0.0, h);

      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        paint,
      );
    }

    // Playback cursor
    canvas.drawLine(
      Offset(cursorX, 0),
      Offset(cursorX, h),
      cursorPaint,
    );
  }

  void _drawPlaceholder(Canvas canvas, Size size) {
    final paint = Paint()..color = AppTheme.waveformUnplayed;
    final mid   = size.height / 2;
    // Draw a flat centre line as placeholder
    canvas.drawLine(Offset(0, mid), Offset(size.width, mid), paint);
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.fraction != fraction || old.waveform != waveform;
}
