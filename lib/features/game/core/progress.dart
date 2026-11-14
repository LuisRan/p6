import 'package:flutter/foundation.dart';

import '../game/game_state.dart';
import 'local_store.dart';

/// Progreso global del jugador (persiste en progress.json).
class PlayerProgress extends ChangeNotifier {
  PlayerProgress([this._store]);
  final JsonFileStore? _store;

  int totalScore = 0;
  int bestScore = 0;
  int gamesWon = 0;
  int gamesLost = 0;
  int totalSeconds = 0;
  int bestLevelClasico = 0;
  int bestLevelReto = 0;

  int bestLevel(GameMode m) =>
      m == GameMode.clasico ? bestLevelClasico : bestLevelReto;

  /// Siguiente nivel a jugar en un modo.
  int nextLevel(GameMode m) => bestLevel(m) + 1;

  Future<void> load() async {
    final m = await _store?.read();
    if (m == null) return;
    int i(String k) => m[k] is int ? m[k] as int : 0;
    totalScore = i('totalScore');
    bestScore = i('bestScore');
    gamesWon = i('gamesWon');
    gamesLost = i('gamesLost');
    totalSeconds = i('totalSeconds');
    bestLevelClasico = i('bestLevelClasico');
    bestLevelReto = i('bestLevelReto');
    notifyListeners();
  }

  /// Registra el resultado de una partida terminada.
  void recordResult(GameState s) {
    totalSeconds += s.elapsedSeconds;
    if (s.won) {
      gamesWon++;
      totalScore += s.score;
      if (s.score > bestScore) bestScore = s.score;
      if (s.mode == GameMode.clasico) {
        if (s.level > bestLevelClasico) bestLevelClasico = s.level;
      } else if (s.level > bestLevelReto) {
        bestLevelReto = s.level;
      }
    } else {
      gamesLost++;
    }
    notifyListeners();
    _store?.write({
      'totalScore': totalScore,
      'bestScore': bestScore,
      'gamesWon': gamesWon,
      'gamesLost': gamesLost,
      'totalSeconds': totalSeconds,
      'bestLevelClasico': bestLevelClasico,
      'bestLevelReto': bestLevelReto,
    });
  }
}
