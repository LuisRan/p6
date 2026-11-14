import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Visor del contenido crudo (texto) de un archivo de guardado.
class RawViewerScreen extends StatelessWidget {
  const RawViewerScreen({super.key, required this.title, required this.content});
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(title, overflow: TextOverflow.ellipsis),
          actions: [
            IconButton(
              tooltip: 'Copiar',
              icon: const Icon(Icons.copy),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: content));
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Copiado')));
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Scrollbar(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    content.isEmpty ? '(archivo vacío)' : content,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
