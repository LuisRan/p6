import 'package:flutter/material.dart';

import '../core/services.dart';
import '../game/game_state.dart';
import '../saves/save_format.dart';

/// Menú de opciones: formato de guardado, jugabilidad y apariencia.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = ServicesScope.of(context).settings;
    return Scaffold(
      appBar: AppBar(title: const Text('Opciones')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: s,
          builder: (context, _) => Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 700),
              child: ListView(padding: const EdgeInsets.all(12), children: [
                const _Header('Guardado'),
                RadioGroup<SaveFormat>(
                  groupValue: s.format,
                  onChanged: (v) => s.update(format: v),
                  child: Column(children: [
                    for (final f in SaveFormat.values)
                      RadioListTile<SaveFormat>(
                        value: f,
                        title: Text(f.label),
                        subtitle: Text('Archivos .${f.extension}'),
                      ),
                  ]),
                ),
                SwitchListTile(
                  title: const Text('Autoguardado de la partida en curso'),
                  value: s.autosave,
                  onChanged: (v) => s.update(autosave: v),
                ),
                const _Header('Jugabilidad'),
                ListTile(
                  title: const Text('Dificultad (tamaño inicial)'),
                  subtitle: SegmentedButton<Difficulty>(
                    segments: const [
                      ButtonSegment(value: Difficulty.facil, label: Text('Fácil 4x4')),
                      ButtonSegment(value: Difficulty.normal, label: Text('Normal 5x5')),
                      ButtonSegment(value: Difficulty.dificil, label: Text('Difícil 6x6')),
                    ],
                    selected: {s.difficulty},
                    onSelectionChanged: (v) => s.update(difficulty: v.first),
                  ),
                ),
                SwitchListTile(
                  title: const Text('Sonido'),
                  value: s.sound,
                  onChanged: (v) => s.update(sound: v),
                ),
                SwitchListTile(
                  title: const Text('Vibración'),
                  value: s.vibration,
                  onChanged: (v) => s.update(vibration: v),
                ),
                const _Header('Apariencia'),
                ListTile(
                  title: const Text('Tema de color'),
                  subtitle: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'guinda', label: Text('Guinda (IPN)')),
                      ButtonSegment(value: 'azul', label: Text('Azul (ESCOM)')),
                    ],
                    selected: {s.palette},
                    onSelectionChanged: (v) => s.update(palette: v.first),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.brightness_auto),
                  title: Text('Claro / oscuro'),
                  subtitle: Text('Automático, según el sistema.'),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.t);
  final String t;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(t,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(color: Theme.of(context).colorScheme.primary)),
      );
}
