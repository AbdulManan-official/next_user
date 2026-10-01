import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// =====================================================================
/// APP COLORS + TEXT STYLES – Single Source of Truth
/// Luxury Dark + Gold Theme (Next Gen & Next User Standard)
/// Font: Plus Jakarta Sans via google_fonts
/// =====================================================================

class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand / Accent Tokens
  // ---------------------------------------------------------------------------
  static const Color gold = Color(0xFFD4AF6A);
  static const Color goldLight = Color(0xFFE8C784);
  static const Color goldDark = Color(0xFFB68A4A);
  static const List<Color> goldGradient = [goldLight, gold, goldDark];

  // ---------------------------------------------------------------------------
  // Backgrounds & Surface Surfaces
  // ---------------------------------------------------------------------------
  static const Color background = Color(0xFF15110C);
  static const Color surface = Color(0xFF1C1712);
  static const Color surfaceElevated = Color(0xFF241D16);
  static const Color surfaceContainerHighest = Color(0xFF2A2219);

  // ---------------------------------------------------------------------------
  // Borders & Dividers
  // ---------------------------------------------------------------------------
  static const Color border = Color(0xFF3A2F22);
  static const Color divider = Color(0xFF2E251B);

  // ---------------------------------------------------------------------------
  // Text Tokens
  // ---------------------------------------------------------------------------
  static const Color textPrimary = Color(0xFFF5EFE6);
  static const Color textSecondary = Color(0xFFB8AFA0);
  static const Color textMuted = Color(0xFF8A8072);
  static const Color textOnGold = Color(0xFF1C1712);

  // ---------------------------------------------------------------------------
  // Status Colors
  // ---------------------------------------------------------------------------
  static const Color success = Color(0xFF10B981); // Solid Vibrant Green
  static const Color error = Color(0xFFEF4444);   // Solid Vibrant Red
  static const Color warning = Color(0xFFE0B45C);
  static const Color info = Color(0xFF7FA8C9);

  // ---------------------------------------------------------------------------
  // Overlays & Shimmer
  // ---------------------------------------------------------------------------
  static const Color overlay = Color(0x99000000);
  static const Color shimmerBase = Color(0xFF211A13);
  static const Color shimmerHighlight = Color(0xFF332A1E);

  // ---------------------------------------------------------------------------
  // Pre-configured LinearGradients
  // ---------------------------------------------------------------------------
  static const LinearGradient goldLinearGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: goldGradient,
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceElevated, surface],
  );

  static const LinearGradient darkShadeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, background],
  );
}

class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Plus Jakarta Sans';

  // Base font helper using GoogleFonts Plus Jakarta Sans
  static TextStyle _display({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.25,
        letterSpacing: letterSpacing,
      );

  static TextStyle _body({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.textSecondary,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height ?? 1.5,
        letterSpacing: letterSpacing,
      );

  // ---------------------------------------------------------------------------
  // Display / Headings
  // ---------------------------------------------------------------------------
  static TextStyle displayLarge =
      _display(size: 40, height: 1.2, weight: FontWeight.w800);
  static TextStyle displayMedium =
      _display(size: 32, height: 1.2, weight: FontWeight.w700);
  static TextStyle displaySmall =
      _display(size: 28, height: 1.25, weight: FontWeight.w700);

  static TextStyle headlineLarge = _display(size: 26, weight: FontWeight.w700);
  static TextStyle headlineMedium = _display(size: 22, weight: FontWeight.w600);
  static TextStyle headlineSmall = _display(size: 18, weight: FontWeight.w600);

  // ---------------------------------------------------------------------------
  // Titles
  // ---------------------------------------------------------------------------
  static TextStyle titleLarge = _body(
      size: 18, weight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle titleMedium = _body(
      size: 16, weight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle titleSmall = _body(
      size: 14, weight: FontWeight.w600, color: AppColors.textPrimary);

  // ---------------------------------------------------------------------------
  // Body Text
  // ---------------------------------------------------------------------------
  static TextStyle bodyLarge = _body(size: 15, height: 1.5);
  static TextStyle bodyMedium = _body(size: 14, height: 1.5);
  static TextStyle bodySmall =
      _body(size: 12, height: 1.4, color: AppColors.textMuted);

  // ---------------------------------------------------------------------------
  // Labels, Buttons, Overline & Hints
  // ---------------------------------------------------------------------------
  static TextStyle labelLarge = _body(
      size: 14, weight: FontWeight.w600, color: AppColors.textPrimary);
  static TextStyle labelMedium = _body(
      size: 12, weight: FontWeight.w500, color: AppColors.textSecondary);
  static TextStyle labelSmall = _body(
      size: 11,
      weight: FontWeight.w500,
      color: AppColors.textMuted,
      letterSpacing: 0.3);

  static TextStyle overline = _body(
      size: 11,
      weight: FontWeight.w600,
      color: AppColors.gold,
      letterSpacing: 2.2);

  static TextStyle button = _body(
      size: 15,
      weight: FontWeight.w600,
      color: AppColors.textOnGold,
      letterSpacing: 0.3);

  static TextStyle hint =
      _body(size: 14, weight: FontWeight.w400, color: AppColors.textMuted);
}
