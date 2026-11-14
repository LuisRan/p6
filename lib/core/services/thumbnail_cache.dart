import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

/// Caché de miniaturas en disco (carpeta de caché de la app) con límite de
/// tamaño total; al excederlo se borran las menos recientemente usadas.
class ThumbnailCache {
  ThumbnailCache(this.dir, {this.maxBytes = 20 * 1024 * 1024, this.size = 128});
  final Directory dir;
  final int maxBytes;
  final int size;

  /// Clave estable: ruta + fecha de modificación + tamaño (se invalida al cambiar).
  static String keyFor(String path, DateTime modified, int length) {
    // FNV-1a de 64 bits (suficiente para nombres de archivo de caché).
    var h = 0xcbf29ce484222325;
    for (final c in '$path|${modified.millisecondsSinceEpoch}|$length'.codeUnits) {
      h ^= c;
      h = (h * 0x100000001b3) & 0x7fffffffffffffff;
    }
    return h.toRadixString(16);
  }

  /// Devuelve el archivo de miniatura (lo genera si no existe) o null si
  /// la imagen no se puede decodificar.
  Future<File?> thumbnailFor(File source) async {
    try {
      final st = await source.stat();
      final out = File(p.join(dir.path, '${keyFor(source.path, st.modified, st.size)}.jpg'));
      if (await out.exists()) {
        await out.setLastModified(DateTime.now()); // marca de uso (LRU)
        return out;
      }
      await dir.create(recursive: true);
      final bytes = await source.readAsBytes();
      final thumb = await compute(_resize, _Job(bytes, size));
      if (thumb == null) return null;
      await out.writeAsBytes(thumb);
      await evict();
      return out;
    } catch (_) {
      return null; // La miniatura es opcional; nunca debe romper la lista.
    }
  }

  /// Aplica el límite de espacio (LRU por fecha de modificación).
  Future<void> evict() async {
    if (!await dir.exists()) return;
    final files = <File>[];
    var total = 0;
    await for (final e in dir.list()) {
      if (e is File) {
        files.add(e);
        total += await e.length();
      }
    }
    if (total <= maxBytes) return;
    files.sort((a, b) => a.statSync().modified.compareTo(b.statSync().modified));
    for (final f in files) {
      if (total <= maxBytes) break;
      total -= await f.length();
      await f.delete();
    }
  }

  Future<int> sizeOnDisk() async {
    if (!await dir.exists()) return 0;
    var t = 0;
    await for (final e in dir.list()) {
      if (e is File) t += await e.length();
    }
    return t;
  }

  Future<void> clear() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  }
}

class _Job {
  _Job(this.bytes, this.size);
  final Uint8List bytes;
  final int size;
}

Uint8List? _resize(_Job j) {
  final image = img.decodeImage(j.bytes);
  if (image == null) return null;
  final r = image.width >= image.height
      ? img.copyResize(image, width: j.size)
      : img.copyResize(image, height: j.size);
  return Uint8List.fromList(img.encodeJpg(r, quality: 75));
}
