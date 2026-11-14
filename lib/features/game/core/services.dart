import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../saves/save_format.dart';
import '../saves/save_game.dart';
import '../saves/save_repository.dart';
import '../saves/serializers.dart';
import 'feedback.dart';
import 'local_store.dart';
import 'progress.dart';
import 'settings.dart';

/// Contenedor de servicios compartidos (inyección simple vía InheritedWidget).
class AppServices {
  AppServices({
    required this.settings,
    required this.progress,
    required this.repo,
    required this.feedback,
    required this.autosaveFile,
  });

  final AppSettings settings;
  final PlayerProgress progress;
  final SaveRepository repo;
  final GameFeedback feedback;

  /// Archivo JSON con la partida en curso (recuperación tras cierre).
  final File autosaveFile;

  /// Guarda la partida en curso (JSON) para poder recuperarla.
  Future<void> writeAutosave(SaveGame g) async {
    try {
      await autosaveFile.writeAsString(
          SaveSerializer.of(SaveFormat.json).encode(g),
          flush: true);
    } catch (_) {}
  }

  Future<void> clearAutosave() async {
    try {
      if (await autosaveFile.exists()) await autosaveFile.delete();
    } catch (_) {}
  }

  /// Lee la partida en curso; null si no hay o está dañada.
  Future<SaveGame?> readAutosave() async {
    try {
      if (!await autosaveFile.exists()) return null;
      final g = SaveSerializer.of(SaveFormat.json)
          .decode(await autosaveFile.readAsString());
      return g.state.finished ? null : g;
    } catch (_) {
      return null;
    }
  }

  /// Crea los servicios sobre el almacenamiento privado de la app:
  /// `<Documents>/saves/` para partidas y `<Documents>/` para el resto.
  static Future<AppServices> create() async {
    final docs = await getApplicationDocumentsDirectory();
    final settings = AppSettings(JsonFileStore(File(p.join(docs.path, 'settings.json'))));
    final progress = PlayerProgress(JsonFileStore(File(p.join(docs.path, 'progress.json'))));
    await settings.load();
    await progress.load();
    return AppServices(
      settings: settings,
      progress: progress,
      repo: SaveRepository(Directory(p.join(docs.path, 'saves'))),
      feedback: GameFeedback(settings),
      autosaveFile: File(p.join(docs.path, 'autosave.json')),
    );
  }
}

class ServicesScope extends InheritedWidget {
  const ServicesScope({super.key, required this.services, required super.child});
  final AppServices services;

  static AppServices of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ServicesScope>()!.services;

  @override
  bool updateShouldNotify(ServicesScope old) => services != old.services;
}
