import 'package:flutter/material.dart';
import '../sensors/sensors_page.dart';
import '../game/core/services.dart' as game;
import '../game/ui/home_screen.dart' as game_ui;

import '../../main.dart';
import '../library/library_view.dart';
import '../settings/settings_view.dart';
import 'browser_view.dart';

/// Estructura adaptable: NavigationBar en pantallas estrechas y
/// NavigationRail a partir de 720 dp de ancho.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.services});
  final AppServices services;
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final Future<game.AppServices> _gameServices = game.AppServices.create();
  final _jump = ValueNotifier<String?>(null);

  static const _dests = [
    (Icons.folder_outlined, Icons.folder, 'Archivos'),
    (Icons.star_outline, Icons.star, 'Favoritos'),
    (Icons.history, Icons.history, 'Recientes'),
    (Icons.settings_outlined, Icons.settings, 'Ajustes'),
    (Icons.sensors, Icons.sensors, 'Sensores'),
    (Icons.extension, Icons.extension, 'Juego'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = widget.services;
    // IndexedStack conserva el estado (ruta actual, portapapeles) al cambiar de sección.
    final pages = IndexedStack(index: _index, children: [
      BrowserView(services: s, jumpTo: _jump),
      LibraryView(services: s, recents: false, onOpenFolder: _openFolder),
      LibraryView(services: s, recents: true, onOpenFolder: _openFolder),
      SettingsView(services: s),
      const SensorsPage(),
      FutureBuilder<game.AppServices>(
        future: _gameServices,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('No se pudo iniciar el juego.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          return game.ServicesScope(services: snapshot.data!, child: const game_ui.HomeScreen());
        },
      ),
    ]);
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 720;
      if (wide) {
        return Scaffold(
          body: Row(children: [
            SafeArea(
              child: NavigationRail(
                selectedIndex: _index,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: [
                  for (final d in _dests)
                    NavigationRailDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: Text(d.$3)),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: pages),
          ]),
        );
      }
      return Scaffold(
        body: pages,
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: [
            for (final d in _dests)
              NavigationDestination(icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
          ],
        ),
      );
    });
  }

  void _openFolder(String path) {
    setState(() => _index = 0);
    _jump.value = path;
  }
}
