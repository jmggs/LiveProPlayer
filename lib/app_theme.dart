import 'package:flutter/material.dart';

class AppTheme {
  // ── Backgrounds ────────────────────────────────────────────────────────────
  static const Color background     = Color(0xFF1A1A1A);
  static const Color surface        = Color(0xFF252525);
  static const Color surfaceHigh    = Color(0xFF2E2E2E);
  static const Color rowSelected    = Color(0xFF1F3A1F);
  static const Color rowPlaying     = Color(0xFF2A5A2A);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color text           = Color(0xFFEEEEEE);
  static const Color textDim        = Color(0xFF888888);
  static const Color textDisabled   = Color(0xFF444444);
  static const Color inactive       = Color(0xFF444444);

  // ── Transport button colors ────────────────────────────────────────────────
  static const Color btnPlay        = Color(0xFF006600);
  static const Color btnPlayActive  = Color(0xFF00AA00);
  static const Color btnCue         = Color(0xFF003888);
  static const Color btnCueActive   = Color(0xFF0055CC);
  static const Color btnPause       = Color(0xFF554400);
  static const Color btnPauseActive = Color(0xFF888800);
  static const Color btnStop        = Color(0xFF660000);
  static const Color btnStopActive  = Color(0xFFAA0000);
  static const Color btnNext        = Color(0xFF333333);
  static const Color btnNextActive  = Color(0xFF555555);

  // ── Waveform ───────────────────────────────────────────────────────────────
  static const Color waveformPlayed   = Color(0xFF00CC00);
  static const Color waveformUnplayed = Color(0xFF005500);
  static const Color waveformCursor   = Color(0xFFFFFFFF);

  // ── VU Meter ───────────────────────────────────────────────────────────────
  static const Color vuGreen  = Color(0xFF00EE00);
  static const Color vuYellow = Color(0xFFFFEE00);
  static const Color vuRed    = Color(0xFFFF2200);
  static const Color vuBg     = Color(0xFF0A0A0A);

  // ── Countdown colors ───────────────────────────────────────────────────────
  static const Color countdownGreen  = Color(0xFF1AFF1A);
  static const Color countdownYellow = Color(0xFFFFD400);
  static const Color countdownRed    = Color(0xFFFF3B30);

  static Color countdownColor(Duration remaining) {
    final secs = remaining.inSeconds;
    if (secs <= 10) return countdownRed;
    if (secs <= 30) return countdownYellow;
    return countdownGreen;
  }

  // ── Mode button ────────────────────────────────────────────────────────────
  static const Color modeActive   = Color(0xFF006699);
  static const Color modeInactive = Color(0xFF333333);

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      surface: surface,
      primary: Color(0xFF00CC00),
      secondary: Color(0xFF0055CC),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111111),
      foregroundColor: text,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: text),
      bodySmall:  TextStyle(color: textDim),
    ),
    dividerColor: const Color(0xFF333333),
    iconTheme: const IconThemeData(color: text),
  );
}
