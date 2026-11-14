import 'package:flutter/material.dart';

/// Renderizador Markdown simple: encabezados, listas, citas, código (bloque y
/// en línea), negritas, cursivas y reglas horizontales.
class MarkdownView extends StatelessWidget {
  const MarkdownView({super.key, required this.source});
  final String source;

  /// Inline: **negrita**, *cursiva*, `código`.
  static List<InlineSpan> inline(String s, TextStyle base, Color codeBg) {
    final re = RegExp(r'\*\*(.+?)\*\*|\*(.+?)\*|`(.+?)`');
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in re.allMatches(s)) {
      if (m.start > last) spans.add(TextSpan(text: s.substring(last, m.start)));
      if (m.group(1) != null) {
        spans.add(TextSpan(text: m.group(1), style: const TextStyle(fontWeight: FontWeight.bold)));
      } else if (m.group(2) != null) {
        spans.add(TextSpan(text: m.group(2), style: const TextStyle(fontStyle: FontStyle.italic)));
      } else {
        spans.add(TextSpan(text: m.group(3), style: TextStyle(fontFamily: 'monospace', backgroundColor: codeBg)));
      }
      last = m.end;
    }
    if (last < s.length) spans.add(TextSpan(text: s.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final body = t.textTheme.bodyLarge!;
    final codeBg = t.colorScheme.surfaceContainerHighest;
    final widgets = <Widget>[];
    var inCode = false;
    final code = StringBuffer();

    for (final line in source.split('\n')) {
      if (line.trimLeft().startsWith('```')) {
        if (inCode) {
          widgets.add(Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: codeBg,
            child: SelectableText(code.toString().trimRight(), style: const TextStyle(fontFamily: 'monospace')),
          ));
          code.clear();
        }
        inCode = !inCode;
        continue;
      }
      if (inCode) { code.writeln(line); continue; }

      final h = RegExp(r'^(#{1,6})\s+(.*)').firstMatch(line);
      if (h != null) {
        final level = h.group(1)!.length;
        final style = [t.textTheme.headlineMedium, t.textTheme.headlineSmall, t.textTheme.titleLarge,
            t.textTheme.titleMedium, t.textTheme.titleSmall, t.textTheme.labelLarge][level - 1]!;
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: SelectableText.rich(TextSpan(
              style: style.copyWith(fontWeight: FontWeight.bold),
              children: inline(h.group(2)!, style, codeBg))),
        ));
      } else if (RegExp(r'^\s*([-*+]|\d+\.)\s+').hasMatch(line)) {
        final m = RegExp(r'^(\s*)([-*+]|\d+\.)\s+(.*)').firstMatch(line)!;
        final bullet = RegExp(r'\d').hasMatch(m.group(2)!) ? m.group(2)! : '•';
        widgets.add(Padding(
          padding: EdgeInsets.only(left: 8.0 + m.group(1)!.length * 4, top: 2, bottom: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 24, child: Text(bullet, style: body)),
            Expanded(child: SelectableText.rich(TextSpan(style: body, children: inline(m.group(3)!, body, codeBg)))),
          ]),
        ));
      } else if (line.startsWith('>')) {
        widgets.add(Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.only(left: 12),
          decoration: BoxDecoration(border: Border(left: BorderSide(color: t.colorScheme.primary, width: 3))),
          child: SelectableText.rich(TextSpan(
              style: body.copyWith(fontStyle: FontStyle.italic),
              children: inline(line.replaceFirst(RegExp(r'^>\s?'), ''), body, codeBg))),
        ));
      } else if (RegExp(r'^\s*(---|\*\*\*|___)\s*$').hasMatch(line)) {
        widgets.add(const Divider());
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else {
        widgets.add(SelectableText.rich(TextSpan(style: body, children: inline(line, body, codeBg))));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }
}
