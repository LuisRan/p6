import 'package:flutter/material.dart';

/// Temas institucionales. Cada uno genera su ColorScheme claro y oscuro
/// desde un color semilla; el modo lo decide el sistema (ThemeMode.system).
enum AppThemeChoice {
  guinda('Guinda (IPN)', Color(0xFF7A1E3F)),
  azul('Azul (ESCOM)', Color(0xFF0B3C8C));

  const AppThemeChoice(this.label, this.seed);
  final String label;
  final Color seed;

  ThemeData build(Brightness b) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: b);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: b == Brightness.light ? seed : scheme.surface,
        foregroundColor: b == Brightness.light ? Colors.white : scheme.onSurface,
      ),
    );
  }
}
