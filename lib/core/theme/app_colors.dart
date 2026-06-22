import 'package:flutter/material.dart';

/// The Bulbul palette: pure-black canvas, white ink, and a tight grey ramp for
/// surfaces and secondary text. Deliberately monochrome (Nothing-OS / Kindle),
/// no gradients. A single, very restrained accent is reserved for progress.
class AppColors {
  const AppColors._();

  static const Color black = Color(0xFF000000); // app background
  static const Color surface = Color(0xFF0D0D0D); // cards
  static const Color surfaceHigh = Color(0xFF161616); // pressed / elevated
  static const Color border = Color(0xFF222222); // hairline outlines

  static const Color white = Color(0xFFFFFFFF); // primary text / icons
  static const Color textSecondary = Color(0xFFB3B3B3); // subtitles (Spotify)
  static const Color textTertiary = Color(0xFF6E6E6E); // hints / metadata

  /// Single accent — used sparingly for reading progress. Kept monochrome-white
  /// by default so the UI stays calm; swap here to introduce a brand hue.
  static const Color accent = Color(0xFFFFFFFF);

  static const Color shimmerBase = Color(0xFF161616);
  static const Color shimmerHighlight = Color(0xFF242424);

  static const Color error = Color(0xFFE5534B);
}
