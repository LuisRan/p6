import 'dart:math';

import 'game_state.dart';
import 'pipes.dart';

/// Resultado de la generación: estado inicial + mínimo de giros óptimo.
class GeneratedLevel {
  GeneratedLevel(this.state, this.minMoves, this.solution);
  final GameState state;
  final int minMoves;

  /// Máscaras de la solución original (útil para pruebas y pistas).
  final List<int> solution;
}

/// Tamaño del tablero para un nivel y dificultad dados.
/// Cada 3 niveles crece una casilla, con tope en 8.
int boardSizeFor(Difficulty d, int level) =>
    (d.baseSize + (level - 1) ~/ 3).clamp(3, 8);

/// Tope de movimientos del modo Reto a partir del mínimo teórico.
int moveLimitFor(int minMoves) => (minMoves * 1.5).ceil() + 3;

/// Genera un nivel de forma determinista a partir de [seed].
///
/// Algoritmo: árbol de expansión aleatorio (Prim) sobre la cuadrícula; cada
/// arista se convierte en conexiones recíprocas entre losetas. Después se
/// gira cada loseta un número aleatorio de veces. El nivel siempre es
/// resoluble porque el estado original es una solución.
GeneratedLevel generateLevel({
  required GameMode mode,
  required Difficulty difficulty,
  required int level,
  required int seed,
}) {
  final size = boardSizeFor(difficulty, level);
  final rng = Random(seed);
  final n = size * size;
  final solution = List<int>.filled(n, 0);
  final source = (size ~/ 2) * size + size ~/ 2;

  // Prim aleatorio: frontera de aristas (desde, dirección).
  final inTree = List<bool>.filled(n, false);
  final frontier = <List<int>>[];
  void addFrontier(int i) {
    final x = i % size, y = i ~/ size;
    for (final dir in const [kN, kE, kS, kW]) {
      final d = kDelta[dir]!;
      final nx = x + d[0], ny = y + d[1];
      if (nx < 0 || ny < 0 || nx >= size || ny >= size) continue;
      if (!inTree[ny * size + nx]) frontier.add([i, dir]);
    }
  }

  inTree[source] = true;
  addFrontier(source);
  while (frontier.isNotEmpty) {
    final e = frontier.removeAt(rng.nextInt(frontier.length));
    final from = e[0], dir = e[1];
    final d = kDelta[dir]!;
    final to = (from ~/ size + d[1]) * size + (from % size + d[0]);
    if (inTree[to]) continue;
    inTree[to] = true;
    solution[from] |= dir;
    solution[to] |= opposite(dir);
    addFrontier(to);
  }

  // Mezcla: giros aleatorios; se garantiza que no empiece resuelto.
  final tiles = List<int>.of(solution);
  var minMoves = 0;
  void scramble() {
    minMoves = 0;
    for (var i = 0; i < n; i++) {
      final r = rng.nextInt(4);
      var m = solution[i];
      for (var k = 0; k < r; k++) {
        m = rotateCw(m);
      }
      tiles[i] = m;
      // giros horarios necesarios para volver a la solución
      minMoves += turnsBetween(m, solution[i]);
    }
  }

  var state = GameState(
    mode: mode,
    difficulty: difficulty,
    level: level,
    size: size,
    seed: seed,
    source: source,
    tiles: tiles,
    moveLimit: 0,
  );
  do {
    scramble();
    state.tiles
      ..clear()
      ..addAll(tiles);
  } while (state.solved);

  state = GameState(
    mode: mode,
    difficulty: difficulty,
    level: level,
    size: size,
    seed: seed,
    source: source,
    tiles: tiles,
    moveLimit: mode == GameMode.reto ? moveLimitFor(minMoves) : 0,
  );
  return GeneratedLevel(state, minMoves, solution);
}
