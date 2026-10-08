import 'package:flutter/material.dart';

/// A class that defines the Sona HUD theme palette based on DESIGN.md.
abstract final class ThemeColors {
  // Canvas & Surfaces
  static const background = Color(0xFF15121A);
  static const canvasAbyss = Color(0xFF08060D);
  static const surfaceContainerLowest = Color(0xFF100D15);
  static const surfaceLow = Color(0xFF1D1A22);
  static const surface = Color(0xFF15121A);
  static const surfaceBase = Color(0xFF0F0B18);
  static const surfaceElevated = Color(0xFF181226);
  static const surfaceContainer = Color(0xFF211E27);
  static const surfaceHigh = Color(0xFF2C2831);
  static const surfaceHighest = Color(0xFF37333C);
  static const surfaceBright = Color(0xFF3B3841);
  static const surfaceVariant = Color(0xFF37333C);

  // Text & Content
  static const onSurface = Color(0xFFE7E0EC);
  static const onSurfaceVariant = Color(0xFFD0C2D5);
  static const inverseSurface = Color(0xFFE7E0EC);
  static const inverseOnSurface = Color(0xFF322F38);

  // Outlines & Borders
  static const outline = Color(0xFF998D9E);
  static const outlineVariant = Color(0xFF4D4353);
  static const surfaceStroke = Color(0x1FC77DFF); // rgba(199, 125, 255, 0.12)

  // Reiatsu & Primary (Spiritual Purple & Amethyst)
  static const primary = Color(0xFF9D4EDD);
  static const primaryLight = Color(0xFFE0B6FF);
  static const onPrimary = Color(0xFF4C007D);
  static const primaryContainer = Color(0xFF9D4EDD);
  static const onPrimaryContainer = Color(0xFFFFFDFF);

  // Secondary
  static const secondary = Color(0xFFC77DFF);
  static const onSecondary = Color(0xFF4C007B);
  static const secondaryContainer = Color(0xFF691A9F);
  static const onSecondaryContainer = Color(0xFFD69EFF);

  // Tertiary
  static const tertiary = Color(0xFF7B2CBF);
  static const onTertiary = Color(0xFF4A007F);
  static const tertiaryContainer = Color(0xFF9A4FDF);

  // Luminescence & Accents
  static const luminescencePure = Color(0xFFFFFFFF);
  static const luminescenceSubtle = Color(0xFFE0AAFF);
  static const textMuted = Color(0x73E0AAFF); // rgba(224, 170, 255, 0.45)

  // Error States
  static const error = Color(0xFFFFB4AB);
  static const onError = Color(0xFF690005);
  static const errorContainer = Color(0xFF93000A);
  static const onErrorContainer = Color(0xFFFFDAD6);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: ThemeColors.background,
    colorScheme: const ColorScheme.dark(
      surface: ThemeColors.surface,
      surfaceContainerLow: ThemeColors.surfaceLow,
      surfaceContainerHigh: ThemeColors.surfaceHigh,
      surfaceContainerHighest: ThemeColors.surfaceHighest,
      primary: ThemeColors.primary,
      onPrimary: ThemeColors.onPrimary,
      primaryContainer: ThemeColors.primaryContainer,
      onPrimaryContainer: ThemeColors.onPrimaryContainer,
      secondary: ThemeColors.secondary,
      onSecondary: ThemeColors.onSecondary,
      secondaryContainer: ThemeColors.secondaryContainer,
      onSecondaryContainer: ThemeColors.onSecondaryContainer,
      tertiary: ThemeColors.tertiary,
      onTertiary: ThemeColors.onTertiary,
      tertiaryContainer: ThemeColors.tertiaryContainer,
      onSurface: ThemeColors.onSurface,
      onSurfaceVariant: ThemeColors.onSurfaceVariant,
      outline: ThemeColors.outline,
      outlineVariant: ThemeColors.outlineVariant,
      error: ThemeColors.error,
      onError: ThemeColors.onError,
      errorContainer: ThemeColors.errorContainer,
      onErrorContainer: ThemeColors.onErrorContainer,
    ),
  );
}


