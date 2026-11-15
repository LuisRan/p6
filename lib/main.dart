import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'core/services/file_service.dart';
import 'core/services/prefs_store.dart';
import 'core/services/seed_data.dart';
import 'core/services/thumbnail_cache.dart';
import 'features/browser/home_shell.dart';
import 'features/game/core/services.dart' as game;

/// Servicios compartidos; se crean una vez en [main].
class AppServices {
  AppServices(this.prefs, this.files, this.thumbs, this.docsDir, this.supportDir);
  final PrefsStore prefs;
  final FileService files;
  final ThumbnailCache thumbs;
  final Directory docsDir, supportDir;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await PrefsStore.load();
  final docs = await getApplicationDocumentsDirectory();
  final support = await getApplicationSupportDirectory();
  final cache = await getTemporaryDirectory(); // cacheDir en Android / Caches en iOS
  // Primer arranque: sembrar datos de ejemplo en el espacio propio.
  if (!prefs.seeded) {
    try {
      await SeedData.seed(docs);
      await prefs.setSeeded();
    } catch (_) {/* no crítico */}
  }
  final services = AppServices(prefs, FileService(),
      ThumbnailCache(Directory('${cache.path}/thumbs')), docs, support);
  final gameServices = await game.AppServices.create();
  runApp(GestorApp(services: services, gameServices: gameServices));
}

class GestorApp extends StatelessWidget {
  const GestorApp({super.key, required this.services, required this.gameServices});
  final AppServices services;
  final game.AppServices gameServices;

  @override
  Widget build(BuildContext context) {
    return game.ServicesScope(
      services: gameServices,
      child: ListenableBuilder(
      listenable: services.prefs,
      builder: (context, _) {
        final t = services.prefs.theme;
        return MaterialApp(
          title: 'Gestor de Archivos',
          debugShowCheckedModeBanner: false,
          theme: t.build(Brightness.light),
          darkTheme: t.build(Brightness.dark),
          themeMode: ThemeMode.system, // claro/oscuro automático
          home: HomeShell(services: services),
        );
      },
      ),
    );
  }
}
