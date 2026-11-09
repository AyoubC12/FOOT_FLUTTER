import 'package:flutter/material.dart';

/// Premium dark palette for FootGPT AI.
abstract final class AppColors {
  static const background = Color(0xFF080D18);
  static const surface = Color(0xFF0C1424);
  static const surfaceElevated = Color(0xFF152033);
  static const card = Color(0xFF111A2B);
  static const border = Color(0xFF243049);
  static const accent = Color(0xFFB6FF3B);
  static const accentMuted = Color(0xFF1C3312);
  static const white = Color(0xFFF7F9FC);
  static const muted = Color(0xFF8B95A8);
  static const danger = Color(0xFFFF5C7A);
  static const warning = Color(0xFFFFC857);
  static const info = Color(0xFF4DA3FF);
  static const live = Color(0xFFFF4D4D);

  static const headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10192C), Color(0xFF080D18), Color(0xFF122016)],
  );
}
