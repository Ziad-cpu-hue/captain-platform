import 'package:flutter/material.dart';

class AppTheme {
  // ── Brand Colors ──────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF1D9E75);
  static const Color primaryDark   = Color(0xFF0F6E56);
  static const Color primaryLight  = Color(0xFFE1F5EE);
  static const Color accent        = Color(0xFFD85A30);
  static const Color accentLight   = Color(0xFFFAECE7);

  static const Color dark          = Color(0xFF0A1628);
  static const Color darkCard      = Color(0xFF111E35);
  static const Color darkSurface   = Color(0xFF182740);

  static const Color warning       = Color(0xFFEF9F27);
  static const Color warningLight  = Color(0xFFFAEEDA);
  static const Color danger        = Color(0xFFE24B4A);
  static const Color dangerLight   = Color(0xFFFCEBEB);
  static const Color success       = Color(0xFF1D9E75);
  static const Color successLight  = Color(0xFFE1F5EE);

  static const Color grey50        = Color(0xFFF1EFE8);
  static const Color grey100       = Color(0xFFD3D1C7);
  static const Color grey400       = Color(0xFF888780);
  static const Color grey600       = Color(0xFF5F5E5A);
  static const Color grey800       = Color(0xFF444441);
  static const Color grey900       = Color(0xFF2C2C2A);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF0A1628);
  static const Color textSecondary = Color(0xFF5F5E5A);
  static const Color textHint      = Color(0xFF888780);
  static const Color border        = Color(0xFFD3D1C7);
  static const Color surface       = Color(0xFFF8F7F4);

  // ── Typography ────────────────────────────────────────────────────────────
  static const String fontFamily = 'CairoFont';

  static TextTheme get textTheme => const TextTheme(
    displayLarge:  TextStyle(fontFamily: fontFamily, fontSize: 32, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.5),
    displayMedium: TextStyle(fontFamily: fontFamily, fontSize: 26, fontWeight: FontWeight.w700, color: textPrimary, letterSpacing: -0.3),
    displaySmall:  TextStyle(fontFamily: fontFamily, fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
    headlineLarge: TextStyle(fontFamily: fontFamily, fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
    headlineMedium:TextStyle(fontFamily: fontFamily, fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
    headlineSmall: TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
    titleLarge:    TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
    titleMedium:   TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
    titleSmall:    TextStyle(fontFamily: fontFamily, fontSize: 13, fontWeight: FontWeight.w500, color: textPrimary),
    bodyLarge:     TextStyle(fontFamily: fontFamily, fontSize: 16, fontWeight: FontWeight.w400, color: textPrimary),
    bodyMedium:    TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w400, color: textPrimary),
    bodySmall:     TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w400, color: textSecondary),
    labelLarge:    TextStyle(fontFamily: fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
    labelMedium:   TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
    labelSmall:    TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
  );

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    colorScheme: ColorScheme.light(
      primary:    primary,
      secondary:  accent,
      surface:    surface,
      background: Colors.white,
      onPrimary:  Colors.white,
      onSecondary:Colors.white,
      onSurface:  textPrimary,
      error:      danger,
    ),
    textTheme: textTheme,
    scaffoldBackgroundColor: surface,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: fontFamily, fontSize: 18,
        fontWeight: FontWeight.w600, color: textPrimary,
      ),
      iconTheme: IconThemeData(color: textPrimary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontFamily: fontFamily, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: danger, width: 1),
      ),
      hintStyle: const TextStyle(fontFamily: fontFamily, color: textHint, fontSize: 14),
    ),
    cardTheme: CardTheme(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(color: border, thickness: 0.5),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: textHint,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 11, fontWeight: FontWeight.w600),
      unselectedLabelStyle: TextStyle(fontFamily: fontFamily, fontSize: 11),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: dark,
      contentTextStyle: const TextStyle(fontFamily: fontFamily, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: grey50,
      labelStyle: const TextStyle(fontFamily: fontFamily, fontSize: 12, fontWeight: FontWeight.w500),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: const BorderSide(color: border, width: 0.5),
    ),
  );
}

// ── Spacing Constants ─────────────────────────────────────────────────────────
class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double h1  = 32;
  static const double h2  = 40;
  static const double h3  = 48;
}

// ── Border Radius ─────────────────────────────────────────────────────────────
class AppRadius {
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double pill = 100;
}
