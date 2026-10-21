import 'package:flutter/material.dart';

abstract final class SonaColors {
  static const abyss = Color(0xFF08060D);
  static const canvas = Color(0xFF100D15);
  static const surface = Color(0xFF15121A);
  static const surfaceLow = Color(0xFF1D1A22);
  static const surfaceMid = Color(0xFF211E27);
  static const surfaceHigh = Color(0xFF2C2831);
  static const surfaceHighest = Color(0xFF37333C);
  static const text = Color(0xFFE7E0EC);
  static const textMid = Color(0xFFD0C2D5);
  static const textMuted = Color(0xFF998D9E);
  static const outline = Color(0xFF4D4353);
  static const specular = Color(0x1FC77DFF);
  static const error = Color(0xFFFFB4AB);

  static Color light(Color accent) => Color.lerp(accent, Colors.white, 0.55)!;
}

abstract final class SonaText {
  static const _grotesk = 'SpaceGrotesk';
  static const _inter = 'Inter';
  static const _mono = 'JetBrainsMono';

  static const headlineLg = TextStyle(
      fontFamily: _grotesk, fontSize: 28, fontWeight: FontWeight.w600,
      height: 36 / 28, letterSpacing: -0.42, color: SonaColors.text);
  static const headlineMd = TextStyle(
      fontFamily: _grotesk, fontSize: 22, fontWeight: FontWeight.w700,
      height: 30 / 22, color: SonaColors.text);
  static const titleMd = TextStyle(
      fontFamily: _inter, fontSize: 15, fontWeight: FontWeight.w600,
      height: 20 / 15, color: SonaColors.text);
  static const bodyMd = TextStyle(
      fontFamily: _inter, fontSize: 13, height: 18 / 13, color: SonaColors.textMid);
  static const bodySm = TextStyle(
      fontFamily: _inter, fontSize: 11, height: 16 / 11, color: SonaColors.textMuted);
  static const labelLg = TextStyle(
      fontFamily: _mono, fontSize: 12, fontWeight: FontWeight.w600,
      height: 16 / 12, letterSpacing: 0.72, color: SonaColors.text);
  static const labelMd = TextStyle(
      fontFamily: _mono, fontSize: 10, fontWeight: FontWeight.w500,
      height: 14 / 10, letterSpacing: 0.8, color: SonaColors.textMid);
  static const labelSm = TextStyle(
      fontFamily: _mono, fontSize: 9, height: 12 / 9, letterSpacing: 0.9,
      color: SonaColors.textMuted);
}