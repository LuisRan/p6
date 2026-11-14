import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/services.dart';
import '../saves/file_actions.dart';
import '../saves/save_exceptions.dart';
import '../saves/save_repository.dart';
import 'dialogs.dart';
import 'game_screen.dart';
import 'raw_viewer_screen.dart';

/// Lista de partidas guardadas con filtro por etiqueta, y acciones:
/// cargar, editar etiquetas, ver contenido crudo, exportar, compartir,
/// eliminar e importar.
class SavesScreen extends StatefulWidget {
  const SavesScreen({super.key});
  @override
  State<SavesScreen> createState() => _SavesScreenState();
}

class _SavesScreenState extends State<SavesScreen> {
  List<SaveEntry>? _entries;
  String? _filterTag; // null = todas
  String _query = '';
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _refresh();
    }
  }

  AppServices get _s => ServicesScope.of(context);

  Future<void> _refresh() async {
    final list = await _s.repo.list();
    if (mounted) setState(() => _entries = list);
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _open(SaveEntry e) async {
    if (!e.isValid) {
      _toast(e.error ?? 'Archivo inválido');
      return;
    }
    try {
      // Se relee del disco por si cambió desde que se listó.
      final g = await _s.repo.load(e.file);
      if (!mounted) return;
      _s.settings.apply(g.settings); // restaura configuración guardada
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => GameScreen(resume: g)));
    } on SaveException catch (ex) {
      _toast(ex.message);
    }
  }

  Future<void> _import() async {
    try {
      final f = await FileActions(_s.repo).importFromPicker();
      if (f != null) {
        _toast('Partida importada');
        _refresh();
      }
    } on SaveException catch (e) {
      _toast('No se importó: ${e.message}');
    } catch (e) {
      _toast('Error al importar: $e');
    }
  }

  Future<void> _action(String a, SaveEntry e) async {
    final repo = _s.repo;
    try {
      switch (a) {
        case 'load':
          await _open(e);
        case 'tags':
          final t = await editTags(context, e.tags);
          if (t != null) {
            await repo.updateMeta(e, tags: SaveRepository.cleanTags(t));
            _refresh();
          }
        case 'raw':
          final text = await repo.readRaw(e.file);
          if (!mounted) return;
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      RawViewerScreen(title: e.fileName, content: text)));
        case 'export':
          final ok = await FileActions(repo).export(e);
          if (ok) _toast('Exportada');
        case 'share':
          final box = context.findRenderObject() as RenderBox?;
          await FileActions(repo).share(e,
              origin: box == null ? null : box.localToGlobal(Offset.zero) & box.size);
        case 'delete':
          final ok = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Eliminar partida'),
              content: Text('¿Eliminar "${e.displayName}"?'),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancelar')),
                FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Eliminar')),
              ],
            ),
          );
          if (ok == true) {
            await repo.delete(e);
            _refresh();
          }
      }
    } on SaveException catch (ex) {
      _toast(ex.message);
    } on FileSystemException catch (ex) {
      _toast('Error de archivo: ${ex.message}');
    } catch (ex) {
      _toast('Error: $ex');
    }
  }

  @override
  Widget build(BuildContext context) {
    final all = _entries;
    final tags = <String>{for (final e in all ?? <SaveEntry>[]) ...e.tags}.toList()
      ..sort();
    final shown = (all ?? [])
        .where((e) => _filterTag == null || e.tags.contains(_filterTag))
        .where((e) =>
            _query.isEmpty ||
            e.displayName.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partidas guardadas'),
        actions: [
          IconButton(
              tooltip: 'Importar',
              icon: const Icon(Icons.file_open),
              onPressed: _import),
          IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh),
              onPressed: _refresh),
        ],
      ),
      body: SafeArea(
        child: all == null
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: TextField(
                        decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Buscar por nombre'),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    if (tags.isNotEmpty)
                      SizedBox(
                        height: 52,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                  label: const Text('Todas'),
                                  selected: _filterTag == null,
                                  onSelected: (_) =>
                                      setState(() => _filterTag = null)),
                            ),
                            for (final t in tags)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: ChoiceChip(
                                    label: Text(t),
                                    selected: _filterTag == t,
                                    onSelected: (_) =>
                                        setState(() => _filterTag = t)),
                              ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: shown.isEmpty
                          ? const Center(child: Text('No hay partidas.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: shown.length,
                              itemBuilder: (_, i) => _tile(shown[i]),
                            ),
                    ),
                  ]),
                ),
              ),
      ),
    );
  }

  Widget _tile(SaveEntry e) {
    final cs = Theme.of(context).colorScheme;
    final g = e.game;
    final date = DateFormat('dd/MM/yyyy HH:mm').format(e.modified);
    return Card(
      color: e.isValid ? null : cs.errorContainer,
      child: ListTile(
        onTap: () => _open(e),
        leading: CircleAvatar(
          backgroundColor: e.isValid ? cs.primaryContainer : cs.error,
          child: Text(e.format.extension.toUpperCase(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        title: Text(e.displayName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: e.isValid
            ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('$date · ${formatBytes(e.bytes)}\n'
                    'Puntos: ${g!.state.score} · Tiempo: ${formatDuration(g.state.elapsedSeconds)}'
                    ' · Nivel ${g.state.level}'),
                if (e.tags.isNotEmpty)
                  Wrap(spacing: 4, children: [
                    for (final t in e.tags)
                      Chip(
                        label: Text(t, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                      ),
                  ]),
              ])
            : Text('$date · ${formatBytes(e.bytes)}\nERROR: ${e.error}',
                style: TextStyle(color: cs.onErrorContainer)),
        isThreeLine: true,
        trailing: PopupMenuButton<String>(
          onSelected: (a) => _action(a, e),
          itemBuilder: (_) => [
            if (e.isValid) const PopupMenuItem(value: 'load', child: Text('Cargar')),
            if (e.isValid)
              const PopupMenuItem(value: 'tags', child: Text('Editar etiquetas')),
            const PopupMenuItem(value: 'raw', child: Text('Ver contenido crudo')),
            const PopupMenuItem(value: 'export', child: Text('Exportar...')),
            const PopupMenuItem(value: 'share', child: Text('Compartir')),
            const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}
