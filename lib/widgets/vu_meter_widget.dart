import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Stereo VU meter — two horizontal bars (L / R) with colour zones.
class VuMeterWidget extends StatelessWidget {
  final double left;   // 0.0–1.0
  final double right;  // 0.0–1.0

  const VuMeterWidget({super.key, required this.left, required this.right});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color:        AppTheme.surface,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VuBar(label: 'L', level: left),
          const SizedBox(height: 4),
          _VuBar(label: 'R', level: right),
        ],
      ),
    );
  }
}

class _VuBar extends StatelessWidget {
  final String label;
  final double level; // 0.0–1.0

  const _VuBar({required this.label, required this.level});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.textDim, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: SizedBox(
            height: 18,
            child: CustomPaint(
              painter: _VuBarPainter(level: level),
            ),
          ),
        ),
      ],
    );
  }
}

class _VuBarPainter extends CustomPainter {
  final double level;

  const _VuBarPainter({required this.level});

  @override
  void paint(Canvas canvas, Size size) {
    const segmentGap    = 2.0;
    const numSegments   = 40;
    const greenEnd      = 0.65;  // 0–65 % green
    const yellowEnd     = 0.85;  // 65–85 % yellow
    // 85–100 % red

    final segW = (size.width - segmentGap * (numSegments - 1)) / numSegments;

    for (int i = 0; i < numSegments; i++) {
      final segFraction = i / numSegments;
      final x = i * (segW + segmentGap);
      final rect = Rect.fromLTWH(x, 0, segW, size.height);

      Color segColor;
      if (segFraction < greenEnd) {
        segColor = AppTheme.vuGreen;
      } else if (segFraction < yellowEnd) {
        segColor = AppTheme.vuYellow;
      } else {
        segColor = AppTheme.vuRed;
      }

      final lit = (i / numSegments) < level;
      final paint = Paint()
        ..color = lit ? segColor : segColor.withValues(alpha: 0.08);

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(1.5)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_VuBarPainter old) => old.level != level;
}
