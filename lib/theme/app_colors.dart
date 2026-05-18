import 'package:flutter/material.dart';

/// NSAT colour palette — "Deep Forest" theme.
///
/// The colour NAMES are kept identical to the original file so every
/// existing screen and widget re-themes automatically. Only the VALUES
/// changed: navy/blue -> deep forest green, with soft cream/green tints.
class AppColors {
  AppColors._();

  // Primary brand — deep forest green + NIU gold
  static const Color primary = Color(0xFF2C6B42); // deep forest green
  static const Color gold = Color(0xFFC9A227);

  // Status
  static const Color green = Color(0xFF3E8E5A); // a brighter success green
  static const Color red = Color(0xFFB0432F); // warm brick red

  // Backgrounds
  static const Color bgLight = Color(0xFFF2F4EC); // soft pale-green page
  static const Color bgCard = Color(0xFFF6F7F0); // card / panel fill
  static const Color bgInfo = Color(0xFFE6F1E5); // soft green tint
  static const Color bgGreenLight = Color(0xFFE6F1E5);
  static const Color bgGoldLight = Color(0xFFF7EED4);
  static const Color bgRedLight = Color(0xFFF5E5E0);
  static const Color bgWarning = Color(0xFFF7EED4); // gold-tint for warnings

  // Text
  static const Color textPrimary = Color(0xFF2C2E27); // near-black, warm
  static const Color textSecondary = Color(0xFF55584C);
  static const Color textMuted = Color(0xFF8A8D7E);
  static const Color textGold = Color(0xFF8A6516);
  static const Color textGreen = Color(0xFF1F4F30);
  static const Color textRed = Color(0xFF7A2E1E);
  static const Color textOrange = Color(0xFF9A5A1A);

  // Borders
  static const Color border = Color(0xFFD9DBCF);
  static const Color borderLight = Color(0xFFE4E6DA);
  static const Color borderGold = Color(0xFFC9A227);
  static const Color borderWarning = Color(0xFFD9A93C);
}