import 'dart:collection';

import 'pipes.dart';

/// Modos de juego.
///  - clasico: sin límite de movimientos, puntúa velocidad y eficiencia.
///  - reto: hay un tope de movimientos; si se agota, se pierde el nivel.
enum GameMode { clasico, reto }

/// Dificultad: define el tamaño base del tablero.
enum Difficulty {
  facil(4),
  normal(5),
  dificil(6);

  const Difficulty(this.baseSize);
  final int baseSize;
}

/// Estado completo y serializable de una partida.
///
/// Todo lo necesario para restaurar la partida *exactamente* vive aquí:
/// el tablero actual, historial de movimientos, puntuación y tiempo.
class GameState {
  GameState({
    required this.mode,
    required this.difficulty,
    required this.level,
    required this.size,
    required this.seed,
    required this.source,
    required List<int> tiles,
    required this.moveLimit,
    List<int>? moves,
    this.score = 0,
    this.elapsedSeconds = 0,
    this.won = false,
  })  : tiles = List<int>.of(tiles),
        moves = List<int>.of(moves ?? const []);

  final GameMode mode;
  final Difficulty difficulty;
  final int level;
  final int size;
  final int seed;

  /// Índice (fila*size+col) de la loseta fuente de energía.
  final int source;

  /// Máscaras actuales de cada loseta (longitud size*size).
  final List<int> tiles;

  /// Tope de movimientos (0 = sin límite).
  final int moveLimit;

  /// Historial: índice de cada loseta girada, en orden cronológico.
  final List<int> moves;

  int score;
  int elapsedSeconds;
  bool won;

  bool get lost => moveLimit > 0 && moves.length >= moveLimit && !won;
  bool get finished => won || lost;

  /// Conjunto de losetas alimentadas desde la fuente (BFS por conexiones
  /// recíprocas: ambos lados deben "mirarse").
  Set<int> poweredSet() {
    final powered = <int>{source};
    final queue = Queue<int>()..add(source);
    while (queue.isNotEmpty) {
      final i = queue.removeFirst();
      final x = i % size, y = i ~/ size;
      for (final dir in const [kN, kE, kS, kW]) {
        if (tiles[i] & dir == 0) continue;
        final d = kDelta[dir]!;
        final nx = x + d[0], ny = y + d[1];
        if (nx < 0 || ny < 0 || nx >= size || ny >= size) continue;
        final j = ny * size + nx;
        if (powered.contains(j)) continue;
        if (tiles[j] & opposite(dir) == 0) continue;
        powered.add(j);
        queue.add(j);
      }
    }
    return powered;
  }

  bool get solved => poweredSet().length == size * size;

  GameState copy() => GameState(
        mode: mode,
        difficulty: difficulty,
        level: level,
        size: size,
        seed: seed,
        source: source,
        tiles: tiles,
        moveLimit: moveLimit,
        moves: moves,
        score: score,
        elapsedSeconds: elapsedSeconds,
        won: won,
      );
}
