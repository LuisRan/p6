/// Formatos de guardado soportados.
enum SaveFormat {
  txt('txt', 'TXT (clave=valor)', 'text/plain'),
  xml('xml', 'XML', 'application/xml'),
  json('json', 'JSON', 'application/json');

  const SaveFormat(this.extension, this.label, this.mimeType);
  final String extension;
  final String label;
  final String mimeType;

  /// Formato a partir de una extensión (sin punto), o null.
  static SaveFormat? fromExtension(String ext) {
    final e = ext.toLowerCase().replaceAll('.', '');
    for (final f in values) {
      if (f.extension == e) return f;
    }
    return null;
  }

  /// Detecta el formato mirando el contenido (para importar archivos
  /// con extensión desconocida).
  static SaveFormat sniff(String content) {
    final t = content.trimLeft();
    if (t.startsWith('{')) return json;
    if (t.startsWith('<')) return xml;
    return txt;
  }
}
