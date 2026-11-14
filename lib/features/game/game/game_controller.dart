import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/feedback.dart';
import '../core/progress.dart';
import '../core/settings.dart';
import '../saves/save_game.dart';
import 'game_state.dart';
import 'generator.dart';
import 'pipes.dart';
import 'scoring.dart';

/// Lógica de la partida en curso. Es un ChangeNotifier para que la UI se
/// reconstruya; no conoce widgets.
class GameController extends ChangeNotifier {
  GameController({
    required this.settings,
    required this.progress,
    required this.feedback,
    this.onChanged,
  });

  final AppSettings settings;
  final PlayerProgress progress;
  final GameFeedback feedback;

  /// Se invoca tras cada cambio relevante (para autoguardado).
  final void Function(GameController)? onChanged;

  late GameState state;
  Set<int> powered = {};
  int minMoves = 0;
  bool _started = false;
  bool _paused = false;
  Timer? _timer;

  /// Callback visual: la UI lanza partículas en la loseta [index].
  void Function(int index, bool nowPowered)? onTileEffect;
  VoidCallback? onWin;

  bool get started => _started;

  /// Nueva partida del modo y nivel dados. [seed] opcional (tests).
  void startNew(GameMode mode, int level, {int? seed}) {
    final g = generateLevel(
      mode: mode,
      difficulty: settings.difficulty,
      level: level,
      seed: seed ?? Random().nextInt(1 << 30),
    );
    state = g.state;
    minMoves = g.minMoves;
    _afterLoad();
  }

  /// Restaura exactamente una partida guardada.
  void restore(SaveGame save) {
    state = save.state.copy();
    // minMoves no se guarda: se recalcula regenerando el nivel de la semilla
    // (determinista). Si no coincide el tamaño se usa una estimación.
    minMoves = _recomputeMinMoves(state);
    _afterLoad();
  }

  int _recomputeMinMoves(GameState s) {
    try {
      final g = generateLevel(
          mode: s.mode, difficulty: s.difficulty, level: s.level, seed: s.seed);
      if (g.state.size == s.size) return g.minMoves;
    } catch (_) {}
    return s.size * s.size;
  }

  void _afterLoad() {
    _started = true;
    _paused = false;
    powered = state.poweredSet();
    _timer?.cancel();
    if (!state.finished) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
    notifyListeners();
  }

  void _tick() {
    if (_paused || state.finished) return;
    state.elapsedSeconds++;
    state.score = computeScore(state, won: false);
    notifyListeners();
  }

  void pause() {
    _paused = true;
    onChanged?.call(this);
  }

  void resume() {
    _paused = false;
  }

  /// Gira la loseta [i] 90° en sentido horario.
  void rotate(int i) {
    if (state.finished || i < 0 || i >= state.tiles.length) return;
    state.tiles[i] = rotateCw(state.tiles[i]);
    state.moves.add(i);
    _applyMove(i);
  }

  /// Deshace el último movimiento (giro antihorario). El historial se acorta.
  bool undo() {
    if (state.finished || state.moves.isEmpty) return false;
    final i = state.moves.removeLast();
    state.tiles[i] = rotateCcw(state.tiles[i]);
    _applyMove(i, undoing: true);
    return true;
  }

  void _applyMove(int i, {bool undoing = false}) {
    final before = powered;
    powered = state.poweredSet();
    state.score = computeScore(state, won: false);
    final nowPowered = powered.contains(i);
    final gained = powered.length > before.length;
    feedback.play(gained ? Sfx.connect : Sfx.tap);
    feedback.haptic(selection: true);
    onTileEffect?.call(i, nowPowered && gained);

    if (state.solved) {
      state.won = true;
      state.score = computeScore(state, won: true);
      _finish(won: true);
    } else if (state.lost) {
      _finish(won: false);
    }
    notifyListeners();
    onChanged?.call(this);
  }

  void _finish({required bool won}) {
    _timer?.cancel();
    progress.recordResult(state);
    feedback.play(won ? Sfx.win : Sfx.lose);
    feedback.haptic(strong: true);
    if (won) onWin?.call();
  }

  /// Empaqueta el estado para guardarlo.
  SaveGame toSave(String name, {List<String> tags = const []}) => SaveGame(
        name: name,
        savedAt: DateTime.now(),
        state: state.copy(),
        tags: tags,
        settings: settings.snapshot(),
      );

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
