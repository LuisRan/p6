import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../main.dart';
import '../browser/file_actions.dart';

/// Lista de favoritos o recientes persistentes.
class LibraryView extends StatelessWidget {
  const LibraryView({super.key, required this.services, required this.recents, required this.onOpenFolder});
  final AppServices services;
  final bool recents;
  final void Function(String folder) onOpenFolder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: services.prefs,
      builder: (context, _) {
        final paths = recents ? services.prefs.recents : services.prefs.favorites;
        return Scaffold(
          appBar: AppBar(
            title: Text(recents ? 'Recientes' : 'Favoritos'),
            actions: [
              if (recents && paths.isNotEmpty)
                IconButton(tooltip: 'Borrar historial', icon: const Icon(Icons.delete_sweep),
                    onPressed: services.prefs.clearRecents),
            ],
          ),
          body: paths.isEmpty
              ? Center(child: Text(recents ? 'Aún no has abierto archivos.' : 'Aún no tienes favoritos.\nUsa el menú de un archivo para añadirlo.', textAlign: TextAlign.center))
              : ListView.builder(
                  itemCount: paths.length,
                  itemBuilder: (_, i) {
                    final path = paths[i];
                    final isDir = FileSystemEntity.isDirectorySync(path);
                    return ListTile(
                      leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
                      title: Text(p.basename(path)),
                      subtitle: Text(p.dirname(path), maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: recents ? null : IconButton(
                        tooltip: 'Quitar', icon: const Icon(Icons.star),
                        onPressed: () => services.prefs.toggleFavorite(path)),
                      onTap: () => isDir ? onOpenFolder(path) : openFileEntry(context, services, path),
                    );
                  },
                ),
        );
      },
    );
  }
}
