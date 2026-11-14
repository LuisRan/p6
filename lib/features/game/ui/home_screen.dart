import 'package:flutter/material.dart';

import '../core/services.dart';
import '../game/game_state.dart';
import '../saves/save_game.dart';
import 'dialogs.dart';
import 'game_screen.dart';
import 'saves_screen.dart';
import 'settings_screen.dart';

/// Menú principal: continuar, nuevas partidas, partidas guardadas, opciones.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  SaveGame? _auto;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _reload();
    }
  }

  Future<void> _reload() async {
    final g = await ServicesScope.of(context).readAutosave();
    if (mounted) setState(() => _auto = g);
  }

  Future<void> _go(Widget w) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final s = ServicesScope.of(context);
    final cs = Theme.of(context).colorScheme;
    final p = s.progress;
    final buttons = <Widget>[
      if (_auto != null)
        FilledButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: Text(
              'Continuar (nivel ${_auto!.state.level}, ${formatDuration(_auto!.state.elapsedSeconds)})'),
          onPressed: () => _go(GameScreen(resume: _auto)),
        ),
      FilledButton.tonalIcon(
        icon: const Icon(Icons.bolt),
        label: Text('Modo Clásico (nivel ${p.nextLevel(GameMode.clasico)})'),
        onPressed: () =>
            _go(GameScreen(mode: GameMode.clasico, level: p.nextLevel(GameMode.clasico))),
      ),
      FilledButton.tonalIcon(
        icon: const Icon(Icons.flag),
        label: Text('Modo Reto (nivel ${p.nextLevel(GameMode.reto)})'),
        onPressed: () =>
            _go(GameScreen(mode: GameMode.reto, level: p.nextLevel(GameMode.reto))),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.folder_open),
        label: const Text('Partidas guardadas'),
        onPressed: () => _go(const SavesScreen()),
      ),
      OutlinedButton.icon(
        icon: const Icon(Icons.settings),
        label: const Text('Opciones'),
        onPressed: () => _go(const SettingsScreen()),
      ),
    ];
    final header = Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.hub, size: 72, color: cs.primary),
      Text('Circuito Guinda',
          style: Theme.of(context).textTheme.headlineMedium),
      const SizedBox(height: 4),
      const Text('Conecta toda la red a la fuente de energía'),
      const SizedBox(height: 12),
      ListenableBuilder(
        listenable: p,
        builder: (_, _) => Wrap(spacing: 8, alignment: WrapAlignment.center, children: [
          Chip(label: Text('Puntos totales: ${p.totalScore}')),
          Chip(label: Text('Mejor: ${p.bestScore}')),
          Chip(label: Text('Victorias: ${p.gamesWon}')),
        ]),
      ),
    ]);
    final menu = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final b in buttons)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: SizedBox(width: double.infinity, child: b)),
      ]),
    );
    return Scaffold(
      body: SafeArea(
        child: OrientationBuilder(builder: (context, o) {
          final landscape = o == Orientation.landscape;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: landscape
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      Flexible(child: header),
                      const SizedBox(width: 32),
                      menu,
                    ])
                  : Column(mainAxisSize: MainAxisSize.min, children: [
                      header,
                      const SizedBox(height: 24),
                      menu,
                    ]),
            ),
          );
        }),
      ),
    );
  }
}
