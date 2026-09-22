// path: lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// E.A.T. brand palette — Black + Neon Green + Alien/UFO.
/// Kept centralized so every screen shares the exact same glow/contrast
/// language instead of drifting into ad-hoc greens.
class AppColors {
  AppColors._();

  static const Color bgBlack = Color(0xFF060A06);
  static const Color surface = Color(0xFF0D140D);
  static const Color surfaceRaised = Color(0xFF121B12);
  static const Color card = Color(0xFF101810);
  static const Color border = Color(0xFF1E2E1E);

  static const Color neon = Color(0xFF39FF6A);
  static const Color neonDeep = Color(0xFF16C24B);
  static const Color neonDim = Color(0xFF1F7A3E);

  static const Color textPrimary = Color(0xFFEAFBEF);
  static const Color textSecondary = Color(0xFF8FA894);
  static const Color textMuted = Color(0xFF5A6E5D);

  static const Color danger = Color(0xFFFF4B4B);
  static const Color warning = Color(0xFFFFC24B);

  static const List<Color> neonGradient = [neon, neonDeep];
}

class AppShadows {
  AppShadows._();

  static List<BoxShadow> neonGlow({double blur = 18, double opacity = 0.35}) {
    return [
      BoxShadow(
        color: AppColors.neon.withOpacity(opacity),
        blurRadius: blur,
        spreadRadius: 0.5,
      ),
    ];
  }

  static List<BoxShadow> subtleCard = [
    BoxShadow(
      color: Colors.black.withOpacity(0.6),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bgBlack,
      canvasColor: AppColors.bgBlack,
      primaryColor: AppColors.neon,
      textTheme: textTheme,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.neon,
        secondary: AppColors.neonDeep,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neon, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.neon,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.neon),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.neon,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
