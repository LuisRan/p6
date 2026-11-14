import 'package:flutter/material.dart';

/// Colores institucionales.
const Color kGuinda = Color(0xFF6A1B3A); // IPN
const Color kAzul = Color(0xFF0B3C8C); // ESCOM

/// Tema para la paleta elegida; el modo claro/oscuro lo decide el sistema
/// (ThemeMode.system en MaterialApp).
ThemeData buildTheme(String palette, Brightness brightness) {
  final seed = palette == 'azul' ? kAzul : kGuinda;
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
    ),
    cardTheme: const CardThemeData(margin: EdgeInsets.symmetric(vertical: 4)),
  );
}
