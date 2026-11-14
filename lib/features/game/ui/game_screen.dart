import 'package:flutter/material.dart';

import '../core/feedback.dart';
import '../core/services.dart';
import '../game/game_controller.dart';
import '../game/game_state.dart';
import '../saves/save_exceptions.dart';
import '../saves/save_game.dart';
import 'board_view.dart';
import 'dialogs.dart';

/// Pantalla de juego. Se abre con una partida nueva ([mode]+[level])
/// o con una partida restaurada ([resume]).
class GameScreen extends StatefulWidget {
  const GameScreen({super.key, this.mode, this.level, this.resume});
  final GameMode? mode;
  final int? level;
  final SaveGame? resume;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  GameController? _c;
  final GlobalKey<BoardViewState> _board = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c != null) return;
    final s = ServicesScope.of(context);
    final c = GameController(
      settings: s.settings,
      progress: s.progress,
      feedback: s.feedback,
      onChanged: (c) {
        // Autoguardado: partida en curso a JSON; al terminar se borra.
        if (c.state.finished) {
          s.clearAutosave();
        } else if (s.settings.autosave) {
          s.writeAutosave(c.toSave('autosave'));
        }
      },
    );
    if (widget.resume != null) {
      c.restore(widget.resume!);
    } else {
      c.startNew(widget.mode ?? GameMode.clasico, widget.level ?? 1);
    }
    c.onWin = () => WidgetsBinding.instance
        .addPostFrameCallback((_) => _board.currentState?.celebrate());
    _c = c;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState st) {
    final c = _c;
    if (c == null) return;
    if (st == AppLifecycleState.resumed) {
      c.resume();
    } else {
      c.pause(); // pausa el reloj y autoguarda
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c?.pause();
    _c?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = ServicesScope.of(context);
    final c = _c!;
    final req = await askSave(context,
        defaultName:
            'Nivel ${c.state.level} ${c.state.mode == GameMode.reto ? "Reto" : "Clásico"}',
        defaultFormat: s.settings.format);
    if (req == null || !mounted) return;
    final msg = ScaffoldMessenger.of(context);
    try {
      final file = await s.repo.save(
          c.toSave(req.name, tags: req.tags), req.format);
      s.feedback.play(Sfx.save);
      final size = await file.length();
      msg.showSnackBar(SnackBar(
          content: Text('Guardada: ${file.uri.pathSegments.last} (${formatBytes(size)})')));
    } on SaveException catch (e) {
      msg.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _c!;
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final st = c.state;
        return Scaffold(
          appBar: AppBar(
            title: Text(
                'Nivel ${st.level} · ${st.mode == GameMode.reto ? "Reto" : "Clásico"}'),
            actions: [
              IconButton(
                tooltip: 'Deshacer',
                icon: const Icon(Icons.undo),
                onPressed: st.finished || st.moves.isEmpty ? null : c.undo,
              ),
              IconButton(
                tooltip: 'Guardar partida',
                icon: const Icon(Icons.save_alt),
                onPressed: _save,
              ),
            ],
          ),
          body: SafeArea(
            child: OrientationBuilder(builder: (context, o) {
              final board = Padding(
                padding: const EdgeInsets.all(12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
                    child: BoardView(key: _board, controller: c),
                  ),
                ),
              );
              final panel = _InfoPanel(
                  controller: c, onSave: _save, onNext: _next, onRetry: _retry);
              if (o == Orientation.landscape) {
                return Row(children: [
                  Expanded(child: board),
                  SizedBox(width: 300, child: SingleChildScrollView(child: panel)),
                ]);
              }
              return Column(children: [
                panel,
                Expanded(child: board),
              ]);
            }),
          ),
        );
      },
    );
  }

  void _next() {
    final c = _c!;
    ServicesScope.of(context).clearAutosave();
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) =>
                GameScreen(mode: c.state.mode, level: c.state.level + 1)));
  }

  void _retry() {
    final c = _c!;
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => GameScreen(mode: c.state.mode, level: c.state.level)));
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.controller,
    required this.onSave,
    required this.onNext,
    required this.onRetry,
  });
  final GameController controller;
  final VoidCallback onSave, onNext, onRetry;

  @override
  Widget build(BuildContext context) {
    final st = controller.state;
    final cs = Theme.of(context).colorScheme;
    final limit = st.moveLimit > 0 ? ' / ${st.moveLimit}' : '';
    Widget stat(IconData i, String label, String v) => Chip(
          avatar: Icon(i, size: 18),
          label: Text('$label $v'),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(spacing: 8, runSpacing: 0, alignment: WrapAlignment.center, children: [
          stat(Icons.timer_outlined, 'Tiempo', formatDuration(st.elapsedSeconds)),
          stat(Icons.touch_app_outlined, 'Mov.', '${st.moves.length}$limit'),
          stat(Icons.star_outline, 'Puntos', '${st.score}'),
          stat(Icons.bolt, 'Conectadas',
              '${controller.powered.length}/${st.size * st.size}'),
        ]),
        if (st.finished)
          Card(
            color: st.won ? cs.primaryContainer : cs.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                Text(
                  st.won ? '¡Circuito completo!' : 'Sin movimientos',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(st.won
                    ? 'Puntuación: ${st.score}'
                    : 'Agotaste el límite de movimientos.'),
                const SizedBox(height: 8),
                Wrap(spacing: 8, children: [
                  if (st.won)
                    FilledButton(onPressed: onNext, child: const Text('Siguiente nivel')),
                  OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
                  OutlinedButton(onPressed: onSave, child: const Text('Guardar')),
                ]),
              ]),
            ),
          ),
      ]),
    );
  }
}
