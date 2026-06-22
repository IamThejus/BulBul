import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography tokens. We lean on the bundled system font (works fully offline,
/// unlike network-fetched Google Fonts) and shape the minimalist feel through
/// weight + letter-spacing: tight, slightly condensed headings; airy body.
class AppTextStyles {
  const AppTextStyles._();

  static const String? _family = null; // system default (Roboto/SF/etc.)

  static const TextStyle display = TextStyle(
    fontFamily: _family,
    fontSize: 34,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.0,
    height: 1.05,
    color: AppColors.white,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: _family,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.white,
  );

  static const TextStyle title = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.white,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.white,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    color: AppColors.textTertiary,
  );

  /// Used for section eyebrows ("CONTINUE READING") — uppercase, wide tracking.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 2.0,
    color: AppColors.textTertiary,
  );
}
