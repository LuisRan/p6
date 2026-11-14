import 'package:flutter/material.dart';

import '../../core/services/syntax_highlighter.dart';
import '../../core/utils/formatters.dart';
import '../../main.dart';
import 'markdown_view.dart';
import 'viewer_page.dart';

/// Visor de txt/md/json/xml. Para json/xml permite alternar formateado/crudo.
class TextViewer extends StatefulWidget {
  const TextViewer({super.key, required this.services, required this.path, required this.kind});
  final AppServices services;
  final String path;
  final ViewerKind kind;
  @override
  State<TextViewer> createState() => _TextViewerState();
}

class _TextViewerState extends State<TextViewer> {
  late Future<(String, bool)> _future;
  bool _pretty = true;

  @override
  void initState() {
    super.initState();
    _future = widget.services.files.readText(widget.path);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<(String, bool)>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('No se pudo leer el archivo: ${snap.error is Exception ? (snap.error as Exception).toString().replaceFirst(RegExp(r"^AppException\(.*?\): "), "") : snap.error}'),
          ));
        }
        final (raw, truncated) = snap.data!;
        var text = raw;
        String? note;
        final structured = widget.kind == ViewerKind.json || widget.kind == ViewerKind.xml;
        if (structured && _pretty && !truncated) {
          try {
            text = widget.kind == ViewerKind.json ? prettyJson(raw) : prettyXml(raw);
          } on FormatException catch (e) {
            note = 'Documento mal formado, se muestra sin formato: ${e.message}';
          } catch (e) {
            note = 'No se pudo dar formato: $e';
          }
        }
        if (truncated) note = 'Archivo grande: se muestran los primeros 300 KB.';

        final dark = Theme.of(context).brightness == Brightness.dark;
        const mono = TextStyle(fontFamily: 'monospace', fontSize: 13, height: 1.35);
        final base = mono.copyWith(color: Theme.of(context).colorScheme.onSurface);

        Widget body;
        if (widget.kind == ViewerKind.markdown) {
          body = MarkdownView(source: text);
        } else if (structured) {
          final tokens = widget.kind == ViewerKind.json
              ? SyntaxHighlighter.tokenizeJson(text)
              : SyntaxHighlighter.tokenizeXml(text);
          body = SelectableText.rich(
              SyntaxHighlighter.toSpan(tokens, SyntaxHighlighter.palette(dark), base));
        } else {
          body = SelectableText(text, style: base);
        }

        return Column(children: [
          if (note != null)
            MaterialBanner(content: Text(note), actions: const [SizedBox.shrink()]),
          if (structured)
            SwitchListTile(
              dense: true,
              title: const Text('Formatear (pretty print)'),
              value: _pretty,
              onChanged: (v) => setState(() => _pretty = v),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              // Scroll horizontal para líneas largas de código.
              child: structured
                  ? SingleChildScrollView(scrollDirection: Axis.horizontal, child: body)
                  : body,
            ),
          ),
        ]);
      },
    );
  }
}
