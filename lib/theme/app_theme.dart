import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// NSAT app theme — "Deep Forest".
///
/// Fonts:
///   - Lora (serif)            -> headings / display text
///   - Quattrocento Sans       -> body text
///
/// Both are fetched automatically by the google_fonts package, so no
/// font files need to be bundled.
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    // Body text uses Quattrocento Sans. This becomes the base text theme.
    final baseTextTheme = GoogleFonts.quattrocentoSansTextTheme();

    // Headings use Lora. We override only the display/headline/title slots.
    final textTheme = baseTextTheme.copyWith(
      displayLarge: GoogleFonts.lora(textStyle: baseTextTheme.displayLarge),
      displayMedium: GoogleFonts.lora(textStyle: baseTextTheme.displayMedium),
      displaySmall: GoogleFonts.lora(textStyle: baseTextTheme.displaySmall),
      headlineLarge: GoogleFonts.lora(textStyle: baseTextTheme.headlineLarge),
      headlineMedium: GoogleFonts.lora(textStyle: baseTextTheme.headlineMedium),
      headlineSmall: GoogleFonts.lora(textStyle: baseTextTheme.headlineSmall),
      titleLarge: GoogleFonts.lora(textStyle: baseTextTheme.titleLarge),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: GoogleFonts.quattrocentoSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 13),
          textStyle: GoogleFonts.quattrocentoSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}