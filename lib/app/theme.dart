import 'package:flutter/material.dart';

class SystemColors {
  static const background = Color(0xFF070B14);
  static const panel = Color(0xFF0E1526);
  static const accent = Color(0xFF3DA9FC);
}

const _snackBarTheme = SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  backgroundColor: SystemColors.panel,
  contentTextStyle: TextStyle(
    color: Color(0xFFE6EEF9),
    fontWeight: FontWeight.w600,
    letterSpacing: 0.6,
  ),
  shape: RoundedRectangleBorder(
    side: BorderSide(color: SystemColors.accent),
  ),
);

ThemeData buildSystemTheme({required bool escuro}) {
  if (!escuro) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: SystemColors.accent,
        brightness: Brightness.light,
      ),
      snackBarTheme: _snackBarTheme,
    );
  }

  final scheme = ColorScheme.fromSeed(
    seedColor: SystemColors.accent,
    brightness: Brightness.dark,
    surface: SystemColors.panel,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: SystemColors.background,
    snackBarTheme: _snackBarTheme,
  );
}
