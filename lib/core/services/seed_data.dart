import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Crea archivos de ejemplo para poder demostrar la app sin datos externos.
/// Idempotente: sólo escribe lo que no existe.
class SeedData {
  static Future<void> seed(Directory root) async {
    final base = Directory(p.join(root.path, 'Ejemplos'));
    await base.create(recursive: true);
    final docs = Directory(p.join(base.path, 'Documentos'))..createSync();
    final media = Directory(p.join(base.path, 'Imagenes'))..createSync();

    Future<void> w(String path, String content) async {
      final f = File(path);
      if (!await f.exists()) await f.writeAsString(content);
    }

    await w(p.join(docs.path, 'nota.txt'),
        'Gestor de archivos - IPN ESCOM\n\nEste es un archivo de texto plano.\nPuedes copiarlo, moverlo, renombrarlo o compartirlo.\n');
    await w(p.join(docs.path, 'lee_me.md'), _md);
    await w(p.join(docs.path, 'alumnos.json'), _json);
    await w(p.join(docs.path, 'plan.xml'), _xml);

    final png = File(p.join(media.path, 'degradado.png'));
    if (!await png.exists()) {
      // Imagen 256x256 generada en código (degradado guinda -> azul).
      final im = img.Image(width: 256, height: 256);
      for (final px in im) {
        final t = px.x / 255;
        px
          ..r = (0x7A + (0x0B - 0x7A) * t).round()
          ..g = (0x1E + (0x3C - 0x1E) * t).round()
          ..b = (0x3F + (0x8C - 0x3F) * t).round()
          ..a = 255;
      }
      await png.writeAsBytes(img.encodePng(im));
    }

    final bin = File(p.join(base.path, 'datos.bin'));
    if (!await bin.exists()) {
      // 2 KB pseudoaleatorios deterministas: formato no soportado.
      await bin.writeAsBytes(List.generate(2048, (i) => (i * 73 + 41) & 0xFF));
    }
  }

  static const _md = '''# Bienvenido

Este es un documento **Markdown** con *énfasis* y `código en línea`.

## Lista

- Explorar carpetas
- Ver JSON y XML con colores
- Rotar y hacer zoom en imágenes

> Una cita de ejemplo.

```
bloque de código
```
''';

  static const _json = '{"curso":"Desarrollo Móvil","escuela":"ESCOM","alumnos":[{"nombre":"Ana","calificacion":9.5,"activo":true},{"nombre":"Luis","calificacion":8,"activo":false,"nota":null}]}';

  static const _xml = '<?xml version="1.0" encoding="UTF-8"?><!-- Plan de ejemplo --><plan id="1" tipo="movil"><materia clave="DM">Desarrollo Móvil</materia><materia clave="BD">Bases de Datos</materia><vacio/></plan>';
}
