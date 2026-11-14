import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../errors/app_exception.dart';

/// Entrada de directorio ya resuelta (evita hacer stat repetidos en la UI).
class FileItem {
  FileItem({
    required this.path,
    required this.isDirectory,
    this.size,
    this.modified,
  });
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? modified;
  String get name => p.basename(path);
  String get extension => p.extension(path).toLowerCase().replaceFirst('.', '');
}

/// Metadatos mostrados en el diálogo de propiedades. null => "No disponible".
class FileMeta {
  FileMeta({
    required this.name,
    required this.path,
    required this.isDirectory,
    this.size,
    this.created,
    this.modified,
    this.mime,
    this.utType,
  });
  final String name, path;
  final bool isDirectory;
  final int? size;
  final DateTime? created, modified;
  final String? mime, utType;
}

typedef ProgressCallback = void Function(double fraction);

/// UTType aproximados (iOS) para las extensiones más comunes.
const _utTypes = {
  'txt': 'public.plain-text',
  'md': 'net.daringfireball.markdown',
  'json': 'public.json',
  'xml': 'public.xml',
  'png': 'public.png',
  'jpg': 'public.jpeg',
  'jpeg': 'public.jpeg',
  'gif': 'com.compuserve.gif',
  'pdf': 'com.adobe.pdf',
  'bin': 'public.data',
  'csv': 'public.comma-separated-values-text',
  'html': 'public.html',
};

/// Servicio de archivos basado en dart:io. No conoce Flutter, por lo que se
/// puede probar con un directorio temporal.
class FileService {
  /// Caracteres no permitidos en nombres (compatibles con Android e iOS).
  static final _badName = RegExp(r'[\\/:*?"<>|\x00]');

  /// Valida un nombre de archivo/carpeta.
  static void validateName(String name) {
    final n = name.trim();
    if (n.isEmpty || n == '.' || n == '..' || _badName.hasMatch(n)) {
      throw AppException(FailureKind.invalidName,
          'El nombre "$name" no es válido (vacío o con caracteres como / \\ : * ? " < > |).');
    }
  }

  /// Traduce errores de dart:io a [AppException].
  Never _translate(Object e, String path) {
    if (e is AppException) throw e;
    if (e is PathNotFoundException) {
      throw AppException(FailureKind.notFound,
          'La ruta ya no está disponible o el archivo no existe.',
          path: path);
    }
    if (e is FileSystemException) {
      final code = e.osError?.errorCode;
      // 28 = ENOSPC (Linux/Android/Darwin), 13/1 = EACCES/EPERM
      if (code == 28) {
        throw AppException(
            FailureKind.noSpace, 'No hay espacio suficiente en el destino.',
            path: path);
      }
      if (code == 13 || code == 1 || code == 30) {
        throw AppException(FailureKind.permissionDenied,
            'Sin permiso para acceder. Puede que se haya revocado; vuelve a elegir la carpeta.',
            path: path);
      }
      if (code == 2) {
        throw AppException(FailureKind.notFound,
            'La ruta ya no está disponible o el archivo no existe.',
            path: path);
      }
      throw AppException(FailureKind.readFailed, 'Operación fallida: ${e.message}',
          path: path);
    }
    throw AppException(FailureKind.unknown, 'Error inesperado: $e', path: path);
  }

  /// Lista un directorio: carpetas primero, luego por nombre (sin distinguir
  /// mayúsculas). Oculta archivos que empiezan con '.'.
  Future<List<FileItem>> list(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) {
        throw AppException(FailureKind.notFound,
            'La carpeta no existe o ya no está disponible.',
            path: dirPath);
      }
      final items = <FileItem>[];
      await for (final e in dir.list(followLinks: false)) {
        if (p.basename(e.path).startsWith('.')) continue;
        try {
          final st = await e.stat();
          items.add(FileItem(
            path: e.path,
            isDirectory: st.type == FileSystemEntityType.directory,
            size: st.type == FileSystemEntityType.directory ? null : st.size,
            modified: st.modified,
          ));
        } catch (_) {
          // Entrada ilegible: se omite en lugar de romper todo el listado.
        }
      }
      items.sort((a, b) {
        if (a.isDirectory != b.isDirectory) return a.isDirectory ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      return items;
    } catch (e) {
      _translate(e, dirPath);
    }
  }

  Future<FileMeta> metadata(String path) async {
    try {
      final st = await FileStat.stat(path);
      if (st.type == FileSystemEntityType.notFound) {
        throw AppException(FailureKind.notFound, 'El archivo no existe.',
            path: path);
      }
      final isDir = st.type == FileSystemEntityType.directory;
      final ext = p.extension(path).toLowerCase().replaceFirst('.', '');
      return FileMeta(
        name: p.basename(path),
        path: path,
        isDirectory: isDir,
        size: isDir ? null : st.size,
        // dart:io no expone fecha de creación (birthtime) en Android/iOS:
        // `changed` es el cambio de inodo en Unix, no la creación.
        created: null,
        modified: st.modified,
        mime: isDir ? 'inode/directory' : lookupMimeType(path),
        utType: isDir ? 'public.folder' : _utTypes[ext],
      );
    } catch (e) {
      _translate(e, path);
    }
  }

  /// Lee texto con límite de bytes; devuelve (texto, truncado).
  Future<(String, bool)> readText(String path, {int maxBytes = 300 * 1024}) async {
    try {
      final f = File(path);
      final len = await f.length();
      final bytes = <int>[];
      await for (final chunk in f.openRead(0, maxBytes)) {
        bytes.addAll(chunk);
      }
      // allowMalformed evita fallar con binarios mal etiquetados.
      return (const Utf8Decoder(allowMalformed: true).convert(bytes),
          len > maxBytes);
    } catch (e) {
      _translate(e, path);
    }
  }

  Future<void> createFolder(String parent, String name) async {
    validateName(name);
    await _assertWritableDir(parent);
    final target = p.join(parent, name.trim());
    if (await FileSystemEntity.type(target) != FileSystemEntityType.notFound) {
      throw AppException(FailureKind.alreadyExists, 'Ya existe "$name".');
    }
    try {
      await Directory(target).create();
    } catch (e) {
      _translate(e, target);
    }
  }

  Future<String> rename(String path, String newName) async {
    validateName(newName);
    final target = p.join(p.dirname(path), newName.trim());
    if (target == path) return path;
    if (await FileSystemEntity.type(target) != FileSystemEntityType.notFound) {
      throw AppException(FailureKind.alreadyExists, 'Ya existe "$newName".');
    }
    try {
      final type = await FileSystemEntity.type(path);
      if (type == FileSystemEntityType.notFound) {
        throw AppException(FailureKind.notFound, 'El archivo ya no existe.',
            path: path);
      }
      final r = type == FileSystemEntityType.directory
          ? await Directory(path).rename(target)
          : await File(path).rename(target);
      return r.path;
    } catch (e) {
      _translate(e, path);
    }
  }

  Future<void> delete(String path) async {
    try {
      final type = await FileSystemEntity.type(path);
      if (type == FileSystemEntityType.notFound) {
        throw AppException(FailureKind.notFound, 'El archivo ya no existe.',
            path: path);
      }
      if (type == FileSystemEntityType.directory) {
        await Directory(path).delete(recursive: true);
      } else {
        await File(path).delete();
      }
    } catch (e) {
      _translate(e, path);
    }
  }

  /// Comprueba que el destino exista y se pueda escribir (archivo sonda).
  Future<void> _assertWritableDir(String dir) async {
    if (!await Directory(dir).exists()) {
      throw AppException(FailureKind.notFound,
          'La carpeta de destino no existe o ya no está disponible.',
          path: dir);
    }
    final probe = File(p.join(dir, '.probe_${DateTime.now().microsecondsSinceEpoch}'));
    try {
      await probe.writeAsString('');
      await probe.delete();
    } catch (_) {
      throw AppException(FailureKind.permissionDenied,
          'No se puede escribir en el destino (permiso denegado o revocado).',
          path: dir);
    }
  }

  /// Genera un nombre libre: "a.txt" -> "a (1).txt".
  Future<String> uniquePath(String dir, String name) async {
    var candidate = p.join(dir, name);
    var i = 1;
    final base = p.basenameWithoutExtension(name);
    final ext = p.extension(name);
    while (await FileSystemEntity.type(candidate) != FileSystemEntityType.notFound) {
      candidate = p.join(dir, '$base ($i)$ext');
      i++;
    }
    return candidate;
  }

  /// Suma de bytes de un archivo o carpeta (para el progreso).
  Future<int> _totalBytes(String path) async {
    final type = await FileSystemEntity.type(path);
    if (type == FileSystemEntityType.directory) {
      var total = 0;
      await for (final e in Directory(path).list(recursive: true)) {
        if (e is File) total += await e.length();
      }
      return total;
    }
    return File(path).length();
  }

  /// Copia archivo o carpeta a [destDir] con progreso (0..1).
  /// Valida origen, destino y que no se copie una carpeta dentro de sí misma.
  Future<String> copy(String src, String destDir, {ProgressCallback? onProgress}) async {
    final type = await FileSystemEntity.type(src);
    if (type == FileSystemEntityType.notFound) {
      throw AppException(FailureKind.notFound, 'El origen ya no existe.', path: src);
    }
    if (type == FileSystemEntityType.directory && p.isWithin(src, destDir) ||
        p.equals(src, destDir)) {
      throw AppException(FailureKind.invalidDestination,
          'No se puede copiar una carpeta dentro de sí misma.');
    }
    await _assertWritableDir(destDir);
    final target = await uniquePath(destDir, p.basename(src));
    try {
      final total = await _totalBytes(src);
      var done = 0;
      Future<void> copyFile(File f, String to) async {
        final out = File(to).openWrite();
        try {
          await for (final chunk in f.openRead()) {
            out.add(chunk);
            done += chunk.length;
            if (total > 0) onProgress?.call(done / total);
          }
        } finally {
          await out.close();
        }
      }

      if (type == FileSystemEntityType.directory) {
        await Directory(target).create();
        await for (final e in Directory(src).list(recursive: true, followLinks: false)) {
          final rel = p.relative(e.path, from: src);
          if (e is Directory) {
            await Directory(p.join(target, rel)).create(recursive: true);
          } else if (e is File) {
            await copyFile(e, p.join(target, rel));
          }
        }
      } else {
        await copyFile(File(src), target);
      }
      onProgress?.call(1);
      return target;
    } catch (e) {
      // Limpieza del destino parcial (p. ej. disco lleno a medias).
      try {
        await _deleteQuiet(target);
      } catch (_) {}
      _translate(e, src);
    }
  }

  Future<void> _deleteQuiet(String path) async {
    final t = await FileSystemEntity.type(path);
    if (t == FileSystemEntityType.directory) {
      await Directory(path).delete(recursive: true);
    } else if (t != FileSystemEntityType.notFound) {
      await File(path).delete();
    }
  }

  /// Mueve: intenta rename atómico y, si cruza volúmenes, copia y borra.
  Future<String> move(String src, String destDir, {ProgressCallback? onProgress}) async {
    if (p.equals(p.dirname(src), destDir)) {
      throw AppException(FailureKind.invalidDestination,
          'El elemento ya está en esa carpeta.');
    }
    final type = await FileSystemEntity.type(src);
    if (type == FileSystemEntityType.notFound) {
      throw AppException(FailureKind.notFound, 'El origen ya no existe.', path: src);
    }
    if (type == FileSystemEntityType.directory && (p.isWithin(src, destDir) || p.equals(src, destDir))) {
      throw AppException(FailureKind.invalidDestination,
          'No se puede mover una carpeta dentro de sí misma.');
    }
    await _assertWritableDir(destDir);
    final target = await uniquePath(destDir, p.basename(src));
    try {
      final r = type == FileSystemEntityType.directory
          ? await Directory(src).rename(target)
          : await File(src).rename(target);
      onProgress?.call(1);
      return r.path;
    } on FileSystemException {
      // Otro volumen (EXDEV): copiar y luego eliminar el origen.
      final copied = await copy(src, destDir, onProgress: onProgress);
      await delete(src);
      return copied;
    }
  }
}
