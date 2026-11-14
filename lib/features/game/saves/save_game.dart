import '../game/game_state.dart';
import 'save_exceptions.dart';

/// Versión actual del esquema de archivos de guardado.
/// Se incrementa cuando cambia la estructura; el parser acepta <= esta.
const int kSchemaVersion = 1;

/// Configuración personalizada guardada junto con la partida.
class SavedSettings {
  const SavedSettings({
    this.sound = true,
    this.vibration = true,
    this.difficulty = Difficulty.normal,
    this.palette = 'guinda',
  });
  final bool sound;
  final bool vibration;
  final Difficulty difficulty;
  final String palette; // 'guinda' | 'azul'

  @override
  bool operator ==(Object other) =>
      other is SavedSettings &&
      other.sound == sound &&
      other.vibration == vibration &&
      other.difficulty == difficulty &&
      other.palette == palette;
  @override
  int get hashCode => Object.hash(sound, vibration, difficulty, palette);
}

/// Contenido lógico de un archivo de guardado, independiente del formato.
class SaveGame {
  SaveGame({
    required this.name,
    required this.savedAt,
    required this.state,
    this.tags = const [],
    this.settings = const SavedSettings(),
    this.schemaVersion = kSchemaVersion,
  });

  final String name;
  final DateTime savedAt;
  final List<String> tags;
  final GameState state;
  final SavedSettings settings;
  final int schemaVersion;

  SaveGame copyWith({String? name, List<String>? tags}) => SaveGame(
        name: name ?? this.name,
        savedAt: savedAt,
        state: state,
        tags: tags ?? this.tags,
        settings: settings,
        schemaVersion: schemaVersion,
      );

  /// Representación neutral (mapas/listas/primitivos) usada por JSON y
  /// como contrato común de validación para XML y TXT.
  Map<String, dynamic> toMap() => {
        'schemaVersion': schemaVersion,
        'name': name,
        'savedAt': savedAt.toUtc().toIso8601String(),
        'tags': tags,
        'game': {
          'mode': state.mode.name,
          'difficulty': state.difficulty.name,
          'level': state.level,
          'size': state.size,
          'seed': state.seed,
          'source': state.source,
          'moveLimit': state.moveLimit,
          'score': state.score,
          'elapsedSeconds': state.elapsedSeconds,
          'won': state.won,
          'tiles': state.tiles,
          'moves': state.moves,
        },
        'settings': {
          'sound': settings.sound,
          'vibration': settings.vibration,
          'difficulty': settings.difficulty.name,
          'palette': settings.palette,
        },
      };

  /// Construye y VALIDA un SaveGame desde un mapa ya parseado.
  /// Lanza [SaveException] con mensaje legible ante cualquier problema.
  static SaveGame fromMap(Object? raw) {
    if (raw is! Map) {
      throw const CorruptSaveException(
          'La estructura raíz del archivo no es válida.');
    }
    final m = Map<String, dynamic>.from(raw);

    final version = _int(m, 'schemaVersion');
    if (version < 1) {
      throw const CorruptSaveException('schemaVersion inválido.');
    }
    if (version > kSchemaVersion) {
      throw UnsupportedVersionException(version, kSchemaVersion);
    }

    final name = _str(m, 'name');
    final savedAt = DateTime.tryParse(_str(m, 'savedAt'));
    if (savedAt == null) {
      throw const CorruptSaveException('Fecha "savedAt" inválida.');
    }
    final tagsRaw = m['tags'];
    final tags = tagsRaw == null
        ? <String>[]
        : (tagsRaw is List
            ? tagsRaw.map((e) => e.toString()).toList()
            : throw const CorruptSaveException('"tags" debe ser una lista.'));

    final g = _map(m, 'game');
    final size = _int(g, 'size');
    if (size < 3 || size > 8) {
      throw CorruptSaveException('Tamaño de tablero fuera de rango: $size.');
    }
    final tiles = _intList(g, 'tiles');
    if (tiles.length != size * size) {
      throw CorruptSaveException(
          'El tablero tiene ${tiles.length} losetas; se esperaban ${size * size}.');
    }
    if (tiles.any((t) => t < 0 || t > 15)) {
      throw const CorruptSaveException('Hay losetas con valores inválidos.');
    }
    final source = _int(g, 'source');
    if (source < 0 || source >= size * size) {
      throw const CorruptSaveException('Posición de fuente inválida.');
    }
    final moves = _intList(g, 'moves');
    if (moves.any((i) => i < 0 || i >= size * size)) {
      throw const CorruptSaveException(
          'El historial contiene movimientos inválidos.');
    }
    final elapsed = _int(g, 'elapsedSeconds');
    final score = _int(g, 'score');
    final limit = _int(g, 'moveLimit');
    if (elapsed < 0 || score < 0 || limit < 0) {
      throw const CorruptSaveException('Valores numéricos negativos.');
    }

    final state = GameState(
      mode: _enum(GameMode.values, _str(g, 'mode'), 'mode'),
      difficulty:
          _enum(Difficulty.values, _str(g, 'difficulty'), 'difficulty'),
      level: _int(g, 'level'),
      size: size,
      seed: _int(g, 'seed'),
      source: source,
      tiles: tiles,
      moveLimit: limit,
      moves: moves,
      score: score,
      elapsedSeconds: elapsed,
      won: _bool(g, 'won'),
    );

    // La sección de ajustes es opcional: si falta, se usan valores por defecto.
    var settings = const SavedSettings();
    if (m['settings'] != null) {
      final s = _map(m, 'settings');
      final palette = _str(s, 'palette');
      settings = SavedSettings(
        sound: _bool(s, 'sound'),
        vibration: _bool(s, 'vibration'),
        difficulty:
            _enum(Difficulty.values, _str(s, 'difficulty'), 'settings.difficulty'),
        palette: (palette == 'azul') ? 'azul' : 'guinda',
      );
    }

    return SaveGame(
      name: name,
      savedAt: savedAt,
      state: state,
      tags: tags,
      settings: settings,
      schemaVersion: version,
    );
  }

  // ---- helpers de validación defensiva (valores *ya tipados* o texto) ----

  static Object _req(Map<String, dynamic> m, String k) {
    final v = m[k];
    if (v == null) throw IncompleteSaveException(k);
    return v;
  }

  static int _int(Map<String, dynamic> m, String k) {
    final v = _req(m, k);
    if (v is int) return v;
    if (v is num && v == v.toInt()) return v.toInt();
    if (v is String) {
      final p = int.tryParse(v.trim());
      if (p != null) return p;
    }
    throw CorruptSaveException('El campo "$k" debe ser un entero.');
  }

  static bool _bool(Map<String, dynamic> m, String k) {
    final v = _req(m, k);
    if (v is bool) return v;
    if (v is String && (v.trim() == 'true' || v.trim() == 'false')) {
      return v.trim() == 'true';
    }
    throw CorruptSaveException('El campo "$k" debe ser true/false.');
  }

  static String _str(Map<String, dynamic> m, String k) {
    final v = _req(m, k);
    if (v is String) return v;
    throw CorruptSaveException('El campo "$k" debe ser texto.');
  }

  static Map<String, dynamic> _map(Map<String, dynamic> m, String k) {
    final v = _req(m, k);
    if (v is Map) return Map<String, dynamic>.from(v);
    throw CorruptSaveException('El campo "$k" debe ser un objeto.');
  }

  static List<int> _intList(Map<String, dynamic> m, String k) {
    final v = _req(m, k);
    if (v is! List) {
      throw CorruptSaveException('El campo "$k" debe ser una lista.');
    }
    final out = <int>[];
    for (final e in v) {
      if (e is int) {
        out.add(e);
      } else if (e is String && int.tryParse(e.trim()) != null) {
        out.add(int.parse(e.trim()));
      } else {
        throw CorruptSaveException('"$k" contiene un valor no numérico: $e.');
      }
    }
    return out;
  }

  static T _enum<T extends Enum>(List<T> values, String v, String field) {
    for (final e in values) {
      if (e.name == v) return e;
    }
    throw CorruptSaveException('Valor desconocido "$v" en "$field".');
  }
}
