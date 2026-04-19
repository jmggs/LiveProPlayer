import 'package:flutter/material.dart';
import '../app_theme.dart';

/// Displays a countdown timer that changes colour based on remaining time.
/// Green > 30s | Yellow ≤ 30s | Red ≤ 10s
class CountdownWidget extends StatelessWidget {
  final Duration remaining;
  final double   fontSize;
  final String?  label;

  const CountdownWidget({
    super.key,
    required this.remaining,
    this.fontSize = 48,
    this.label,
  });

  String _format(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h.toString().padLeft(2, '0')}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.countdownColor(remaining);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Text(
            label!,
            style: const TextStyle(
              color: AppTheme.textDim,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
        Text(
          _format(remaining),
          style: TextStyle(
            color:      color,
            fontSize:   fontSize,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
