import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Material 3 theming for Virtual Diary.
class AppColors {
  AppColors._();

  static const Color seed = Color(0xFF6750A4); // deep violet, journal-y
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color danger = Color(0xFFD32F2F);

  static const List<Color> streakGradient = [Color(0xFFF2994A), Color(0xFFF2C94C)];
  static const List<Color> primaryGradient = [Color(0xFF6750A4), Color(0xFF9C6ADE)];
}

class AppTheme {
  AppTheme._();

  static ThemeData light = _build(Brightness.light);
  static ThemeData dark = _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: brightness,
    );

    final baseTextTheme = ThemeData(brightness: brightness).textTheme;
    final bodyTextTheme = GoogleFonts.interTextTheme(baseTextTheme);
    final textTheme = bodyTextTheme.copyWith(
      headlineLarge: GoogleFonts.poppins(textStyle: bodyTextTheme.headlineLarge, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.poppins(textStyle: bodyTextTheme.headlineMedium, fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.poppins(textStyle: bodyTextTheme.headlineSmall, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.poppins(textStyle: bodyTextTheme.titleLarge, fontWeight: FontWeight.w600),
      titleMedium: GoogleFonts.poppins(textStyle: bodyTextTheme.titleMedium, fontWeight: FontWeight.w600),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          textStyle: baseTextTheme.titleLarge,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
