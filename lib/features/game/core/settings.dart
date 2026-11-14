import 'package:flutter/foundation.dart';

import '../game/game_state.dart';
import '../saves/save_format.dart';
import '../saves/save_game.dart';
import 'local_store.dart';

/// Ajustes del usuario (persisten en settings.json).
class AppSettings extends ChangeNotifier {
  AppSettings([this._store]);
  final JsonFileStore? _store;

  bool sound = true;
  bool vibration = true;
  Difficulty difficulty = Difficulty.normal;
  String palette = 'guinda'; // 'guinda' | 'azul'
  SaveFormat format = SaveFormat.json;
  bool autosave = true;

  Future<void> load() async {
    final m = await _store?.read();
    if (m == null) return;
    sound = m['sound'] is bool ? m['sound'] as bool : sound;
    vibration = m['vibration'] is bool ? m['vibration'] as bool : vibration;
    autosave = m['autosave'] is bool ? m['autosave'] as bool : autosave;
    difficulty = Difficulty.values.firstWhere(
        (d) => d.name == m['difficulty'],
        orElse: () => difficulty);
    format = SaveFormat.fromExtension('${m['format']}') ?? format;
    palette = m['palette'] == 'azul' ? 'azul' : 'guinda';
    notifyListeners();
  }

  /// Aplica un cambio y persiste.
  void update({
    bool? sound,
    bool? vibration,
    Difficulty? difficulty,
    String? palette,
    SaveFormat? format,
    bool? autosave,
  }) {
    this.sound = sound ?? this.sound;
    this.vibration = vibration ?? this.vibration;
    this.difficulty = difficulty ?? this.difficulty;
    this.palette = palette ?? this.palette;
    this.format = format ?? this.format;
    this.autosave = autosave ?? this.autosave;
    notifyListeners();
    _store?.write({
      'sound': this.sound,
      'vibration': this.vibration,
      'difficulty': this.difficulty.name,
      'palette': this.palette,
      'format': this.format.extension,
      'autosave': this.autosave,
    });
  }

  SavedSettings snapshot() => SavedSettings(
      sound: sound, vibration: vibration, difficulty: difficulty, palette: palette);

  void apply(SavedSettings s) => update(
      sound: s.sound,
      vibration: s.vibration,
      difficulty: s.difficulty,
      palette: s.palette);
}
