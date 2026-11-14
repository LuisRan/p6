import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../core/errors/app_exception.dart';
import '../../core/services/file_service.dart';
import '../../core/utils/formatters.dart';
import '../../main.dart';
import '../viewer/viewer_page.dart';
import 'file_actions.dart';
import 'thumb_widget.dart';

enum _Op { copy, move }

/// Explorador: raíces (espacio de la app + carpetas elegidas), breadcrumbs,
/// lista/cuadrícula adaptable y operaciones de archivo.
class BrowserView extends StatefulWidget {
  const BrowserView({super.key, required this.services, required this.jumpTo});
  final AppServices services;

  /// Otras secciones (favoritos/recientes) piden navegar a una carpeta.
  final ValueNotifier<String?> jumpTo;
  @override
  State<BrowserView> createState() => _BrowserViewState();
}

class _BrowserViewState extends State<BrowserView> {
  AppServices get s => widget.services;
  late String _root;
  late String _current;
  Future<List<FileItem>>? _listing;
  (_Op, String)? _clipboard;

  List<(String, String)> get _roots => [
        ('Documentos de la app', s.docsDir.path),
        ('Soporte de la app', s.supportDir.path),
        for (final r in s.prefs.externalRoots) (p.basename(r), r),
      ];

  @override
  void initState() {
    super.initState();
    _root = _current = s.docsDir.path;
    _reload();
    widget.jumpTo.addListener(_onJump);
    s.prefs.addListener(_onPrefs);
  }

  @override
  void dispose() {
    widget.jumpTo.removeListener(_onJump);
    s.prefs.removeListener(_onPrefs);
    super.dispose();
  }

  void _onPrefs() => setState(() {}); // favoritos / raíces cambiaron

  void _onJump() {
    final target = widget.jumpTo.value;
    if (target == null) return;
    widget.jumpTo.value = null;
    // Busca la raíz que contiene el destino; si no, lo usa como raíz propia.
    final root = _roots.map((r) => r.$2).where((r) => p.equals(r, target) || p.isWithin(r, target)).firstOrNull;
    setState(() { _root = root ?? target; });
    _go(target);
  }

  void _go(String path) {
    setState(() {
      _current = path;
      _listing = s.files.list(path);
    });
  }

  void _reload() => _go(_current);

  bool get _atRoot => p.equals(_current, _root);

  // ---- Carpetas externas -------------------------------------------------
  Future<void> _pickFolder() async {
    // Explicar la finalidad ANTES de abrir el selector del sistema.
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        icon: const Icon(Icons.folder_open),
        title: const Text('Elegir una carpeta'),
        content: const Text(
            'Para explorar archivos fuera del espacio de la app, el sistema te mostrará su selector de carpetas. '
            'Sólo tendremos acceso a la carpeta que elijas; no accedemos al resto del almacenamiento. '
            'Todo funciona sin conexión y no se envía ningún dato.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Continuar')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final dir = await FilePicker.getDirectoryPath(dialogTitle: 'Elige una carpeta');
      if (dir == null) return; // cancelado
      await s.files.list(dir); // valida que realmente se pueda leer
      await s.prefs.addRoot(dir);
      setState(() => _root = dir);
      _go(dir);
    } catch (e) {
      if (mounted) {
        showFailure(context, e is AppException ? e : AppException(FailureKind.permissionDenied,
            'No se pudo acceder a la carpeta elegida. Prueba con otra o importa archivos con "Importar".'));
      }
    }
  }

  /// Importa archivos elegidos con el selector del sistema a la carpeta actual.
  Future<void> _import() async {
    try {
      final res = await FilePicker.pickFiles();
      if (res.isEmpty || !mounted) return;
      await runWithProgress(context, 'Importando…', (report) async {
        for (var i = 0; i < res.length; i++) {
          final path = res[i].path;
          if (path == null) continue;
          await s.files.copy(path, _current, onProgress: (f) => report((i + f) / res.length));
        }
      });
      _reload();
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  // ---- Operaciones ---------------------------------------------------------
  Future<void> _rename(FileItem it) async {
    final n = await askText(context, title: 'Renombrar', initial: it.name);
    if (n == null) return;
    try {
      final np = await s.files.rename(it.path, n);
      if (s.prefs.isFavorite(it.path)) {
        await s.prefs.forget(it.path);
        await s.prefs.toggleFavorite(np);
      }
      _reload();
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
  }

  Future<void> _delete(FileItem it) async {
    final ok = await confirm(context,
        title: 'Eliminar',
        body: it.isDirectory
            ? '¿Eliminar la carpeta "${it.name}" y todo su contenido? No se puede deshacer.'
            : '¿Eliminar "${it.name}"? No se puede deshacer.');
    if (!ok) return;
    try {
      await s.files.delete(it.path);
      await s.prefs.forget(it.path);
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
    _reload();
  }

  Future<void> _newFolder() async {
    final n = await askText(context, title: 'Nueva carpeta', action: 'Crear');
    if (n == null) return;
    try {
      await s.files.createFolder(_current, n);
    } catch (e) {
      if (mounted) showFailure(context, e);
    }
    _reload();
  }

  Future<void> _paste() async {
    final c = _clipboard;
    if (c == null) return;
    final (op, src) = c;
    final isMove = op == _Op.move;
    final r = await runWithProgress(context, isMove ? 'Moviendo…' : 'Copiando…', (report) async {
      return isMove
          ? await s.files.move(src, _current, onProgress: report)
          : await s.files.copy(src, _current, onProgress: report);
    });
    if (r != null) {
      setState(() => _clipboard = null);
      if (mounted) showInfo(context, isMove ? 'Elemento movido.' : 'Elemento copiado.');
    }
    _reload();
  }

  void _open(FileItem it) {
    if (it.isDirectory) {
      _go(it.path);
    } else {
      openFileEntry(context, s, it.path);
    }
  }

  // ---- UI ------------------------------------------------------------------
  Widget _breadcrumbs() {
    final rel = _atRoot ? <String>[] : p.split(p.relative(_current, from: _root));
    final rootName = _roots.where((r) => r.$2 == _root).map((r) => r.$1).firstOrNull ?? p.basename(_root);
    final crumbs = <Widget>[
      _crumb(rootName, _root),
      for (var i = 0; i < rel.length; i++) ...[
        const Icon(Icons.chevron_right, size: 18),
        _crumb(rel[i], p.joinAll([_root, ...rel.take(i + 1)])),
      ],
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true, // mantiene visible el tramo final
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(children: crumbs),
    );
  }

  Widget _crumb(String label, String path) =>
      TextButton(onPressed: p.equals(path, _current) ? null : () => _go(path), child: Text(label));

  Widget _menu(FileItem it) {
    final fav = s.prefs.isFavorite(it.path);
    return PopupMenuButton<String>(
      tooltip: 'Acciones',
      onSelected: (v) async {
        switch (v) {
          case 'open': _open(it);
          case 'meta': await showMetadata(context, s, it.path);
          case 'fav': await s.prefs.toggleFavorite(it.path);
          case 'copy': setState(() => _clipboard = (_Op.copy, it.path)); showInfo(context, 'Elige una carpeta y pulsa "Pegar".');
          case 'move': setState(() => _clipboard = (_Op.move, it.path)); showInfo(context, 'Elige una carpeta y pulsa "Pegar".');
          case 'rename': await _rename(it);
          case 'delete': await _delete(it);
          case 'share': await shareFile(context, it.path);
          case 'export': await exportFile(context, it.path);
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'open', child: Text('Abrir')),
        const PopupMenuItem(value: 'meta', child: Text('Propiedades')),
        PopupMenuItem(value: 'fav', child: Text(fav ? 'Quitar de favoritos' : 'Añadir a favoritos')),
        const PopupMenuItem(value: 'copy', child: Text('Copiar')),
        const PopupMenuItem(value: 'move', child: Text('Mover')),
        const PopupMenuItem(value: 'rename', child: Text('Renombrar')),
        if (!it.isDirectory) const PopupMenuItem(value: 'share', child: Text('Compartir')),
        if (!it.isDirectory) const PopupMenuItem(value: 'export', child: Text('Exportar')),
        const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
      ],
    );
  }

  Widget _leading(FileItem it, double size) {
    if (it.isDirectory) return Icon(Icons.folder, size: size * .8, color: Theme.of(context).colorScheme.primary);
    if (ViewerKind.fromPath(it.path) == ViewerKind.image) {
      return ImageThumb(key: ValueKey(it.path), cache: s.thumbs, path: it.path, size: size);
    }
    final icon = switch (ViewerKind.fromPath(it.path)) {
      ViewerKind.json || ViewerKind.xml => Icons.data_object,
      ViewerKind.markdown || ViewerKind.text => Icons.description,
      _ => Icons.insert_drive_file,
    };
    return Icon(icon, size: size * .8);
  }

  Widget _body(List<FileItem> items) {
    if (items.isEmpty) return const Center(child: Text('Carpeta vacía'));
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth >= 720) {
        // Pantallas anchas: cuadrícula con tarjetas.
        return GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 220, mainAxisExtent: 150, crossAxisSpacing: 8, mainAxisSpacing: 8),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final it = items[i];
            return Card(
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _open(it),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(children: [
                    Align(alignment: Alignment.topRight, child: SizedBox(height: 32, child: _menu(it))),
                    Expanded(child: Center(child: _leading(it, 56))),
                    Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(it.isDirectory ? 'Carpeta' : formatBytes(it.size), style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              ),
            );
          },
        );
      }
      return ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final it = items[i];
          return ListTile(
            leading: SizedBox(width: 48, height: 48, child: Center(child: _leading(it, 48))),
            title: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(it.isDirectory ? formatDate(it.modified) : '${formatBytes(it.size)} · ${formatDate(it.modified)}'),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (s.prefs.isFavorite(it.path)) const Icon(Icons.star, color: Colors.amber, size: 18),
              _menu(it),
            ]),
            onTap: () => _open(it),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _atRoot,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _go(p.dirname(_current));
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Archivos'),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.folder_special),
              tooltip: 'Ubicaciones',
              onSelected: (v) {
                if (v == '__pick') {
                  _pickFolder();
                  return;
                }
                setState(() => _root = v);
                _go(v);
              },
              itemBuilder: (_) => [
                for (final r in _roots) PopupMenuItem(value: r.$2, child: Text(r.$1)),
                const PopupMenuDivider(),
                const PopupMenuItem(value: '__pick', child: Text('Elegir otra carpeta…')),
              ],
            ),
            IconButton(tooltip: 'Importar archivos', icon: const Icon(Icons.file_upload), onPressed: _import),
            IconButton(tooltip: 'Nueva carpeta', icon: const Icon(Icons.create_new_folder), onPressed: _newFolder),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Align(alignment: Alignment.centerLeft, child: _breadcrumbs()),
          ),
        ),
        floatingActionButton: _clipboard == null
            ? null
            : FloatingActionButton.extended(
                onPressed: _paste,
                icon: const Icon(Icons.paste),
                label: Text(_clipboard!.$1 == _Op.move ? 'Mover aquí' : 'Pegar aquí'),
              ),
        body: FutureBuilder<List<FileItem>>(
          future: _listing,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              final e = snap.error;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 8),
                    Text(e is AppException ? e.message : 'No se pudo leer la carpeta.', textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      OutlinedButton(onPressed: _reload, child: const Text('Reintentar')),
                      if (!_atRoot) OutlinedButton(onPressed: () => _go(_root), child: const Text('Ir a la raíz')),
                      if (s.prefs.externalRoots.contains(_root))
                        OutlinedButton(
                          onPressed: () async {
                            await s.prefs.removeRoot(_root);
                            setState(() => _root = _current = s.docsDir.path);
                            _reload();
                          },
                          child: const Text('Quitar carpeta'),
                        ),
                    ]),
                  ]),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () async => _reload(),
              child: _body(snap.data!),
            );
          },
        ),
      ),
    );
  }
}
