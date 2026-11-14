import 'dart:convert';
import 'dart:io';

/// Almacén mínimo de JSON en un archivo (ajustes y progreso).
/// Tolerante a fallos: si el archivo falta o está dañado devuelve null.
class JsonFileStore {
  JsonFileStore(this.file);
  final File file;

  Future<Map<String, dynamic>?> read() async {
    try {
      if (!await file.exists()) return null;
      final v = jsonDecode(await file.readAsString());
      return v is Map<String, dynamic> ? v : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> write(Map<String, dynamic> data) async {
    try {
      await file.parent.create(recursive: true);
      final tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(data), flush: true);
      await tmp.rename(file.path);
    } catch (_) {
      // Un fallo de persistencia no debe tumbar la UI.
    }
  }
}
