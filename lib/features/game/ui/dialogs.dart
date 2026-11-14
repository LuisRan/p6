import 'package:flutter/material.dart';

import '../saves/save_format.dart';

class SaveRequest {
  SaveRequest(this.name, this.tags, this.format);
  final String name;
  final List<String> tags;
  final SaveFormat format;
}

List<String> parseTags(String s) =>
    s.split(RegExp(r'[,;]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

/// Diálogo "Guardar partida": nombre, etiquetas y formato.
Future<SaveRequest?> askSave(BuildContext context,
    {required String defaultName, required SaveFormat defaultFormat}) {
  final name = TextEditingController(text: defaultName);
  final tags = TextEditingController();
  var format = defaultFormat;
  return showDialog<SaveRequest>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Guardar partida'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            TextField(
              controller: tags,
              decoration: const InputDecoration(
                  labelText: 'Etiquetas (separadas por coma)'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SaveFormat>(
              initialValue: format,
              decoration: const InputDecoration(labelText: 'Formato'),
              items: [
                for (final f in SaveFormat.values)
                  DropdownMenuItem(value: f, child: Text(f.label)),
              ],
              onChanged: (v) => setState(() => format = v ?? format),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(
                ctx, SaveRequest(name.text, parseTags(tags.text), format)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}

/// Editor de etiquetas de una partida existente.
Future<List<String>?> editTags(BuildContext context, List<String> current) {
  final c = TextEditingController(text: current.join(', '));
  return showDialog<List<String>>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Editar etiquetas'),
      content: TextField(
        controller: c,
        autofocus: true,
        decoration: const InputDecoration(
            labelText: 'Etiquetas', helperText: 'Separadas por coma'),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, parseTags(c.text)),
            child: const Text('Aceptar')),
      ],
    ),
  );
}

String formatDuration(int seconds) {
  final m = seconds ~/ 60, s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

String formatBytes(int b) =>
    b < 1024 ? '$b B' : '${(b / 1024).toStringAsFixed(1)} KB';
