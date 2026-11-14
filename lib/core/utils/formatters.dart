import 'dart:convert';

import 'package:xml/xml.dart';

/// Tamaño legible (base 1024). Devuelve 'No disponible' si es null.
String formatBytes(int? bytes) {
  if (bytes == null || bytes < 0) return 'No disponible';
  if (bytes < 1024) return '$bytes B';
  const units = ['KB', 'MB', 'GB', 'TB'];
  double v = bytes / 1024;
  int i = 0;
  while (v >= 1024 && i < units.length - 1) {
    v /= 1024;
    i++;
  }
  return '${v.toStringAsFixed(v >= 100 ? 0 : 1)} ${units[i]}';
}

/// Fecha 'dd/MM/yyyy HH:mm' (sin depender de intl). null -> 'No disponible'.
String formatDate(DateTime? d) {
  if (d == null) return 'No disponible';
  String two(int n) => n.toString().padLeft(2, '0');
  final l = d.toLocal();
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

/// Pretty print de JSON con sangría de 2 espacios. Lanza [FormatException].
String prettyJson(String source) {
  final decoded = jsonDecode(source);
  return const JsonEncoder.withIndent('  ').convert(decoded);
}

/// Pretty print de XML. Lanza [XmlException] (subtipo de FormatException).
String prettyXml(String source) {
  final doc = XmlDocument.parse(source);
  return doc.toXmlString(pretty: true, indent: '  ');
}
