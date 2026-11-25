import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Design tokens mirrored directly from Presensi Makerindo Web (`resources/css/app.css` & Blade views).
class ChronoColors {
  ChronoColors._();

  // Brand Core (Slate Navy + Sky Blue)
  static const Color dark = Color(0xFF0F172A); // slate-900 / chrono-dark
  static const Color navy = Color(0xFF1E293B); // slate-800 / chrono-navy
  static const Color slate = Color(0xFF334155); // slate-700
  static const Color sky = Color(0xFF0284C7); // sky-600 / chrono-sky
  static const Color skyDark = Color(0xFF0369A1); // sky-700
  static const Color skyLight = Color(0xFF38BDF8); // sky-400
  static const Color skySoft = Color(0xFFE0F2FE); // sky-100
  static const Color skyTint = Color(0xFFF0F9FF); // sky-50

  // Neutral Surfaces & Borders
  static const Color background = Color(0xFFF8FAFC); // slate-50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF1F5F9); // slate-100
  static const Color border = Color(0xFFE2E8F0); // slate-200
  static const Color borderStrong = Color(0xFFCBD5E1); // slate-300

  // Text Hierarchy (WCAG AA compliant on white & slate-50)
  static const Color textPrimary = Color(0xFF0F172A); // slate-900
  static const Color textSecondary = Color(0xFF475569); // slate-600
  static const Color textMuted = Color(0xFF64748B); // slate-500

  // Semantic States
  static const Color success = Color(0xFF059669); // emerald-600
  static const Color successDark = Color(0xFF065F46); // emerald-800
  static const Color successBg = Color(0xFFECFDF5); // emerald-50
  static const Color successBorder = Color(0xFFA7F3D0); // emerald-200

  static const Color warning = Color(0xFFD97706); // amber-600
  static const Color warningDark = Color(0xFF92400E); // amber-800
  static const Color warningBg = Color(0xFFFFFBEB); // amber-50
  static const Color warningBorder = Color(0xFFFDE68A); // amber-200

  static const Color danger = Color(0xFFDC2626); // red-600 / rose-600
  static const Color dangerDark = Color(0xFF991B1B); // red-800
  static const Color dangerBg = Color(0xFFFEF2F2); // red-50
  static const Color dangerBorder = Color(0xFFFECACA); // red-200
}

class ChronoTheme {
  ChronoTheme._();

  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w600,
    Color color = ChronoColors.textPrimary,
    double? letterSpacing,
  }) {
    return GoogleFonts.jetBrainsMono(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  static ThemeData build() {
    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: ChronoColors.background,
      colorScheme: const ColorScheme.light(
        primary: ChronoColors.dark,
        onPrimary: Colors.white,
        secondary: ChronoColors.sky,
        onSecondary: Colors.white,
        surface: ChronoColors.surface,
        onSurface: ChronoColors.textPrimary,
        error: ChronoColors.danger,
        onError: Colors.white,
        outline: ChronoColors.border,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: ChronoColors.textPrimary,
          letterSpacing: -0.4,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: ChronoColors.textPrimary,
          letterSpacing: -0.3,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: ChronoColors.textPrimary,
          letterSpacing: -0.2,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: ChronoColors.textPrimary,
        ),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(
          color: ChronoColors.textPrimary,
        ),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(
          color: ChronoColors.textSecondary,
        ),
        bodySmall: baseTextTheme.bodySmall?.copyWith(
          color: ChronoColors.textMuted,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: ChronoColors.surface,
        foregroundColor: ChronoColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: ChronoColors.textPrimary,
          letterSpacing: -0.2,
        ),
        shape: const Border(
          bottom: BorderSide(color: ChronoColors.border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ChronoColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: ChronoColors.textMuted,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ChronoColors.slate,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronoColors.borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronoColors.borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronoColors.dark, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronoColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ChronoColors.danger, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ChronoColors.dark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: ChronoColors.borderStrong,
          disabledForegroundColor: ChronoColors.textMuted,
          minimumSize: const Size(48, 48),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ChronoColors.dark,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: const BorderSide(color: ChronoColors.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ChronoColors.border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ChronoColors.dark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
