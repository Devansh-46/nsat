import 'package:flutter/material.dart';

/// NSAT design tokens — "Verdant Daylight" palette.
///
/// One-to-one with the design spec section 2. Names match the spec's
/// CSS custom properties (mesh1 ↔ --mesh-1) so the spec stays the
/// source of truth.
///
/// LEGACY NOTE: a number of names from the previous deep-forest theme
/// (`bgLight`, `bgCard`, `textPrimary`, `border`, etc.) are kept as
/// aliases pointing at the new tokens. This lets every existing screen
/// keep compiling while the redesign rolls out one screen at a time.
class AppColors {
  AppColors._();

  // --- Ambient mesh ---
  static const Color mesh1 = Color(0xFFF8E8D4);
  static const Color mesh2 = Color(0xFFDCE9DD);
  static const Color mesh3 = Color(0xFFE2EDF1);
  static const Color mesh4 = Color(0xFFF2E6D6);
  static const Color bgBase = Color(0xFFF4EFE3);

  // --- Surfaces ---
  static const Color ivory = Color(0xFFF4EFE3);
  static const Color paper = Color(0x9EFFFDF7);
  static const Color paper2 = Color(0x6BFFFDF7);
  static const Color bone = Color(0x0A0F2A1F);
  static const Color boneDeep = Color(0x1A0F2A1F);

  // --- Ink ---
  static const Color ink = Color(0xFF0F2A1F);
  static const Color ink2 = Color(0xFF1F3D2E);
  static const Color ink3 = Color(0xFF4A5C50);
  static const Color ink4 = Color(0xFF7C8B7F);
  static const Color ink5 = Color(0xFFB9C2B7);

  // --- Brand accents ---
  static const Color forest = Color(0xFF2C6B42);
  static const Color forest2 = Color(0xFF3E8E5A);
  static const Color gold = Color(0xFFC9A227);
  static const Color gold2 = Color(0xFFE0BC4A);
  static const Color clay = Color(0xFFB0432F);
  static const Color success = forest2;

  // --- Tints ---
  static const Color forestTint = Color(0x1A2C6B42);
  static const Color forestTint2 = Color(0x243E8E5A);
  static const Color goldTint = Color(0x24C9A227);
  static const Color goldTint2 = Color(0x38E0BC4A);
  static const Color clayTint = Color(0x1FB0432F);
  static const Color clayTint2 = Color(0x2EB0432F);

  // --- Glass ---
  static const Color glassBorder = Color(0xC7FFFFFF);
  static const Color glassBorderInner = Color(0x8CFFFFFF);
  static const LinearGradient glassBg = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xA8FFFEFA), Color(0x66FFFEFA)],
  );
  static const LinearGradient glassBgStrong = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xD1FFFEFA), Color(0x8CFFFEFA)],
  );

  // --- Emphasis ---
  static const Color emp = Color(0xFF0F2A1F);
  static const Color onEmp = Color(0xFFF4EFE3);
  static const Color onEmpSoft = Color(0xB8F6F1E3);
  static const Color onEmpSofter = Color(0x8CF6F1E3);
  static const Color empRule = Color(0x24F6F1E3);

  // --- Lines ---
  static const Color rule = Color(0x140F2A1F);
  static const Color rule2 = Color(0x1A0F2A1F);
  static const Color line = Color(0x1F0F2A1F);
  static const Color line2 = Color(0x140F2A1F);

  // =================================================================
  // LEGACY ALIASES — keep old screens compiling during migration.
  // =================================================================

  @Deprecated('Use AppColors.forest')
  static const Color primary = forest;
  @Deprecated('Use AppColors.clay')
  static const Color red = clay;
  @Deprecated('Use AppColors.forest2')
  static const Color green = forest2;

  @Deprecated('Use AppColors.bgBase')
  static const Color bgLight = Color.fromARGB(227, 244, 239, 227);
  @Deprecated('Use AppColors.paper or glassBg')
  static const Color bgCard = Color(0xFFF6F7F0);
  @Deprecated('Use AppColors.forestTint')
  static const Color bgInfo = forestTint;
  @Deprecated('Use AppColors.forestTint')
  static const Color bgGreenLight = forestTint;
  @Deprecated('Use AppColors.goldTint')
  static const Color bgGoldLight = goldTint;
  @Deprecated('Use AppColors.clayTint')
  static const Color bgRedLight = clayTint;
  @Deprecated('Use AppColors.goldTint')
  static const Color bgWarning = goldTint;

  @Deprecated('Use AppColors.ink')
  static const Color textPrimary = ink;
  @Deprecated('Use AppColors.ink3')
  static const Color textSecondary = ink3;
  @Deprecated('Use AppColors.ink4')
  static const Color textMuted = ink4;
  @Deprecated('Use AppColors.gold')
  static const Color textGold = Color(0xFF8A6516);
  @Deprecated('Use AppColors.forest')
  static const Color textGreen = Color(0xFF1F4F30);
  @Deprecated('Use AppColors.clay')
  static const Color textRed = Color(0xFF7A2E1E);
  @Deprecated('Use AppColors.clay')
  static const Color textOrange = Color(0xFF9A5A1A);

  @Deprecated('Use AppColors.line')
  static const Color border = Color(0xFFD9DBCF);
  @Deprecated('Use AppColors.rule')
  static const Color borderLight = Color(0xFFE4E6DA);
  @Deprecated('Use AppColors.gold')
  static const Color borderGold = gold;
  @Deprecated('Use AppColors.gold')
  static const Color borderWarning = Color(0xFFD9A93C);
}
