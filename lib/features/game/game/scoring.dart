import 'game_state.dart';

/// Puntuación de un estado de partida (pura y testeable).
///
/// base = 100 por loseta; se resta 8 por cada movimiento y 1 por segundo,
/// con un mínimo de 10% de la base. El modo Reto multiplica por 1.5 y al
/// ganar se suma un bonus por nivel.
int computeScore(GameState s, {required bool won}) {
  final base = s.size * s.size * 100;
  final raw = base - s.moves.length * 8 - s.elapsedSeconds;
  var score = raw < base ~/ 10 ? base ~/ 10 : raw;
  if (s.mode == GameMode.reto) score = (score * 1.5).round();
  if (won) score += s.level * 50;
  return score;
}
