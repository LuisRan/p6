import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'save_exceptions.dart';
import 'save_format.dart';
import 'save_game.dart';
import 'serializers.dart';

/// Una fila de la lista de partidas: metadatos + (si es válido) el contenido.
/// Si el archivo está corrupto, [game] es null y [error] explica por qué;
/// así un archivo malo nunca impide ver ni cargar los demás.
class SaveEntry {
  SaveEntry({
    required this.file,
    required this.format,
    required this.bytes,
    required this.modified,
    this.game,
    this.error,
  });

  final File file;
  final SaveFormat format;
  final int bytes;
  final DateTime modified;
  final SaveGame? game;
  final String? error;

  bool get isValid => game != null;
  String get fileName => p.basename(file.path);
  String get displayName => game?.name ?? fileName;
  List<String> get tags => game?.tags ?? const [];
}

/// Acceso a la carpeta `saves/` (almacenamiento privado de la app).
///
/// El directorio se inyecta para poder probar con un directorio temporal.
/// En la app real es `getApplicationDocumentsDirectory()/saves`.
class SaveRepository {
  SaveRepository(this.directory);
  final Directory directory;

  Future<void> _ensureDir() async {
    if (!await directory.exists()) await directory.create(recursive: true);
  }

  /// Limpia nombre/etiquetas para que sean seguros en los tres formatos
  /// (sin caracteres de control, sin espacios en los extremos).
  static String cleanText(String s) =>
      s.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), ' ').trim();

  static List<String> cleanTags(Iterable<String> tags) {
    final seen = <String>{};
    final out = <String>[];
    for (final t in tags) {
      final c = cleanText(t);
      if (c.isNotEmpty && seen.add(c.toLowerCase())) out.add(c);
    }
    return out;
  }

  static String _slug(String name) {
    final s = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return s.isEmpty ? 'partida' : (s.length > 30 ? s.substring(0, 30) : s);
  }

  /// Guarda [game] en [format]. Devuelve el archivo creado.
  /// Escribe a un temporal y renombra, para no dejar archivos a medias.
  Future<File> save(SaveGame game, SaveFormat format, {File? replace}) async {
    await _ensureDir();
    final clean = SaveGame(
      name: cleanText(game.name).isEmpty ? 'Partida' : cleanText(game.name),
      savedAt: game.savedAt,
      state: game.state,
      tags: cleanTags(game.tags),
      settings: game.settings,
    );
    final content = SaveSerializer.of(format).encode(clean);
    final target = replace ??
        File(p.join(directory.path,
            '${_slug(clean.name)}_${clean.savedAt.millisecondsSinceEpoch}.${format.extension}'));
    try {
      final tmp = File('${target.path}.tmp');
      await tmp.writeAsString(content, flush: true);
      await tmp.rename(target.path);
    } on FileSystemException catch (e) {
      throw SaveIoException('No se pudo escribir el archivo: ${e.message}');
    }
    return target;
  }

  /// Lee y valida un archivo. Lanza [SaveException].
  Future<SaveGame> load(File file) async {
    final text = await readRaw(file);
    return decodeText(text, _formatOf(file, text));
  }

  static SaveGame decodeText(String text, SaveFormat format) =>
      SaveSerializer.of(format).decode(text);

  SaveFormat _formatOf(File f, String text) =>
      SaveFormat.fromExtension(p.extension(f.path)) ?? SaveFormat.sniff(text);

  /// Contenido crudo (para el visor). Tolera bytes no UTF-8.
  Future<String> readRaw(File file) async {
    try {
      final bytes = await file.readAsBytes();
      return utf8.decode(bytes, allowMalformed: true);
    } on FileSystemException catch (e) {
      throw SaveIoException('No se pudo leer el archivo: ${e.message}');
    }
  }

  /// Lista todos los archivos con metadatos, más recientes primero.
  Future<List<SaveEntry>> list() async {
    if (!await directory.exists()) return [];
    final out = <SaveEntry>[];
    await for (final e in directory.list()) {
      if (e is! File) continue;
      final fmt = SaveFormat.fromExtension(p.extension(e.path));
      if (fmt == null) continue; // ignora .tmp y otros
      final stat = await e.stat();
      SaveGame? game;
      String? error;
      try {
        game = await load(e);
      } on SaveException catch (ex) {
        error = ex.message;
      } catch (ex) {
        error = 'Error inesperado: $ex';
      }
      out.add(SaveEntry(
        file: e,
        format: fmt,
        bytes: stat.size,
        modified: stat.modified,
        game: game,
        error: error,
      ));
    }
    out.sort((a, b) => b.modified.compareTo(a.modified));
    return out;
  }

  Future<void> delete(SaveEntry e) async {
    if (await e.file.exists()) await e.file.delete();
  }

  /// Cambia nombre/etiquetas reescribiendo el archivo en su mismo formato.
  Future<void> updateMeta(SaveEntry e, {String? name, List<String>? tags}) async {
    final g = e.game;
    if (g == null) throw const CorruptSaveException('Archivo corrupto.');
    await save(g.copyWith(name: name, tags: tags), e.format, replace: e.file);
  }

  /// Importa un archivo externo: lo valida y, si es correcto, lo copia a
  /// `saves/` normalizando la extensión. Si no es válido lanza y NO copia.
  Future<File> importContent(String text, String originalName) async {
    final ext = p.extension(originalName);
    final fmt = SaveFormat.fromExtension(ext) ?? SaveFormat.sniff(text);
    final game = decodeText(text, fmt); // valida (lanza si falla)
    final imported = SaveGame(
      name: game.name,
      savedAt: game.savedAt,
      state: game.state,
      tags: game.tags,
      settings: game.settings,
    );
    await _ensureDir();
    // Para no pisar una partida existente se usa marca de tiempo actual.
    final target = File(p.join(directory.path,
        '${_slug(game.name)}_imp${DateTime.now().microsecondsSinceEpoch}.${fmt.extension}'));
    return save(imported, fmt, replace: target);
  }
}
