import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// NSAT typography & theme — matches design spec §4.
///
/// Three font families:
///   - Instrument Serif (display)  -> headings, stat values, italic punctuation
///   - Geist (body)                 -> paragraphs, labels, buttons, eyebrows
///   - JetBrains Mono (numeric)     -> IDs, timers, scores, dates
///
/// All loaded via google_fonts at runtime — no asset registration needed.
///
/// Use the helpers (display, displaySm, body, eyebrow, mono, italicSpan)
/// instead of building TextStyles by hand. Keeps every screen on-system.
class AppTheme {
  AppTheme._();

  // -------------------------------------------------------------------
  // Font helpers — call these wherever you'd reach for TextStyle.
  // -------------------------------------------------------------------

  /// Instrument Serif — display heading. Default 32px screen title.
  static TextStyle display({double size = 32, Color color = AppColors.ink}) {
    return GoogleFonts.instrumentSerif(
      fontSize: size,
      height: 1.05,
      letterSpacing: -size * 0.02,
      color: color,
    );
  }

  /// Smaller display — card titles. Default 24px.
  static TextStyle displaySm({double size = 24, Color color = AppColors.ink}) {
    return GoogleFonts.instrumentSerif(
      fontSize: size,
      height: 1.15,
      letterSpacing: -size * 0.01,
      color: color,
    );
  }

  /// Geist body text. Default 14.5px.
  static TextStyle body({
    double size = 14.5,
    Color color = AppColors.ink2,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.inter(
      fontSize: size,
      height: 1.5,
      color: color,
      fontWeight: weight,
    );
  }

  /// Eyebrow label — UPPERCASE, tracked, muted. Section / field labels.
  static TextStyle eyebrow({Color color = AppColors.ink4}) {
    return GoogleFonts.inter(
      fontSize: 10.5,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.18 * 10.5,
      height: 1.2,
      color: color,
    );
  }

  /// JetBrains Mono with tabular numerics — for IDs, timers, scores, dates.
  static TextStyle mono({
    double size = 13,
    Color color = AppColors.ink,
    FontWeight weight = FontWeight.w400,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      letterSpacing: -size * 0.005,
      color: color,
      fontWeight: weight,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  /// Italic span helper — for the italic-word-in-heading rule (spec §4).
  ///
  ///   RichText(
  ///     text: TextSpan(
  ///       style: AppTheme.display(),
  ///       children: [
  ///         const TextSpan(text: 'Welcome back, '),
  ///         AppTheme.italicSpan('applicant.'),
  ///       ],
  ///     ),
  ///   );
  ///
  /// One italic word per heading — that's the rule. Don't stack them.
  static TextSpan italicSpan(String text, {Color? color}) {
    return TextSpan(
      text: text,
      style: GoogleFonts.instrumentSerif(
        fontStyle: FontStyle.italic,
        color: color,
      ),
    );
  }

  // -------------------------------------------------------------------
  // The Flutter ThemeData itself.
  // -------------------------------------------------------------------

  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme();

    final textTheme = baseTextTheme.copyWith(
      // Headings -> Instrument Serif.
      displayLarge: GoogleFonts.instrumentSerif(
        fontSize: 56,
        height: 1.05,
        letterSpacing: -56 * 0.025,
        color: AppColors.ink,
      ),
      displayMedium: GoogleFonts.instrumentSerif(
        fontSize: 40,
        height: 1.08,
        letterSpacing: -40 * 0.02,
        color: AppColors.ink,
      ),
      displaySmall: GoogleFonts.instrumentSerif(
        fontSize: 26,
        height: 1.15,
        letterSpacing: -26 * 0.01,
        color: AppColors.ink,
      ),
      headlineLarge: GoogleFonts.instrumentSerif(
        fontSize: 32,
        color: AppColors.ink,
      ),
      headlineMedium: GoogleFonts.instrumentSerif(
        fontSize: 24,
        color: AppColors.ink,
      ),
      headlineSmall: GoogleFonts.instrumentSerif(
        fontSize: 20,
        color: AppColors.ink,
      ),
      titleLarge: GoogleFonts.instrumentSerif(
        fontSize: 22,
        color: AppColors.ink,
      ),

      // Body -> Geist (defaults inherit), explicit sizes for clarity.
      bodyLarge: GoogleFonts.inter(
        fontSize: 15,
        height: 1.5,
        color: AppColors.ink2,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14.5,
        height: 1.5,
        color: AppColors.ink2,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 13,
        height: 1.45,
        color: AppColors.ink3,
      ),

      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.ink,
      ),
      labelMedium: GoogleFonts.inter(
        fontSize: 12.5,
        color: AppColors.ink3,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 11,
        color: AppColors.ink4,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.forest,
        primary: AppColors.forest,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.bgBase,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.ink,
        elevation: 0,
      ),
      // We use custom NiuButton / glass widgets — these themes only act
      // as fallbacks for stray ElevatedButton / OutlinedButton calls.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.ink,
          foregroundColor: AppColors.ivory,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          elevation: 0,
          textStyle: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.ink, width: 1),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          textStyle: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
