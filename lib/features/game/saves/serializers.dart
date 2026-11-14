import 'dart:convert';

import 'package:xml/xml.dart';

import 'save_exceptions.dart';
import 'save_format.dart';
import 'save_game.dart';

/// Contrato común de los tres serializadores.
abstract class SaveSerializer {
  const SaveSerializer();
  SaveFormat get format;
  String encode(SaveGame game);

  /// Decodifica con parser defensivo. Nunca lanza algo que no sea
  /// [SaveException].
  SaveGame decode(String content) {
    if (content.trim().isEmpty) throw const EmptySaveException();
    try {
      return SaveGame.fromMap(parse(content));
    } on SaveException {
      rethrow;
    } catch (e) {
      throw CorruptSaveException('No se pudo interpretar el archivo: $e');
    }
  }

  /// Convierte el texto a mapa neutral (sin validar semántica).
  Object? parse(String content);

  static SaveSerializer of(SaveFormat f) => switch (f) {
        SaveFormat.txt => const TxtSerializer(),
        SaveFormat.xml => const XmlSerializer(),
        SaveFormat.json => const JsonSerializer(),
      };
}

// ---------------------------------------------------------------- JSON ----

class JsonSerializer extends SaveSerializer {
  const JsonSerializer();
  @override
  SaveFormat get format => SaveFormat.json;

  @override
  String encode(SaveGame game) =>
      const JsonEncoder.withIndent('  ').convert(game.toMap());

  @override
  Object? parse(String content) {
    try {
      return jsonDecode(content);
    } on FormatException catch (e) {
      throw CorruptSaveException('JSON inválido: ${e.message}');
    }
  }
}

// ----------------------------------------------------------------- XML ----

/// Estructura:
/// `<save schemaVersion="1"><name/><savedAt/><tags/><game/><settings/></save>`
/// Se usan nombres de elemento en inglés idénticos a las claves del mapa
/// para que la conversión sea mecánica.
class XmlSerializer extends SaveSerializer {
  const XmlSerializer();
  @override
  SaveFormat get format => SaveFormat.xml;

  @override
  String encode(SaveGame game) {
    final m = game.toMap();
    final g = m['game'] as Map<String, dynamic>;
    final s = m['settings'] as Map<String, dynamic>;
    final b = XmlBuilder();
    b.processing('xml', 'version="1.0" encoding="UTF-8"');
    b.element('save', attributes: {'schemaVersion': '${m['schemaVersion']}'},
        nest: () {
      b.element('name', nest: m['name']);
      b.element('savedAt', nest: m['savedAt']);
      b.element('tags', nest: () {
        for (final t in game.tags) {
          b.element('tag', nest: t);
        }
      });
      b.element('game', nest: () {
        for (final k in const [
          'mode', 'difficulty', 'level', 'size', 'seed', 'source',
          'moveLimit', 'score', 'elapsedSeconds', 'won',
        ]) {
          b.element(k, nest: '${g[k]}');
        }
        b.element('tiles', nest: (g['tiles'] as List).join(','));
        b.element('moves', nest: (g['moves'] as List).join(','));
      });
      b.element('settings', nest: () {
        for (final e in s.entries) {
          b.element(e.key, nest: '${e.value}');
        }
      });
    });
    return b.buildDocument().toXmlString(pretty: true, indent: '  ');
  }

  @override
  Object? parse(String content) {
    final XmlDocument doc;
    try {
      doc = XmlDocument.parse(content);
    } on XmlException catch (e) {
      throw CorruptSaveException('XML mal formado: ${e.message}');
    }
    final root = doc.rootElement;
    if (root.name.local != 'save') {
      throw const CorruptSaveException(
          'El elemento raíz debe ser <save>.');
    }
    String? text(XmlElement p, String n) {
      final el = p.getElement(n);
      return el?.innerText;
    }

    Map<String, dynamic>? section(String n) {
      final el = root.getElement(n);
      if (el == null) return null;
      return {for (final c in el.childElements) c.name.local: c.innerText};
    }

    List<String> csv(String? v) => (v == null || v.trim().isEmpty)
        ? <String>[]
        : v.split(',').map((e) => e.trim()).toList();

    final game = section('game');
    final settings = section('settings');
    if (game != null) {
      game['tiles'] = csv(game['tiles'] as String?);
      game['moves'] = csv(game['moves'] as String?);
      // Si el elemento no existía, se elimina para que se reporte "falta".
      if (root.getElement('game')!.getElement('tiles') == null) {
        game.remove('tiles');
      }
      if (root.getElement('game')!.getElement('moves') == null) {
        game.remove('moves');
      }
    }
    return {
      'schemaVersion': root.getAttribute('schemaVersion'),
      'name': text(root, 'name'),
      'savedAt': text(root, 'savedAt'),
      'tags': root
              .getElement('tags')
              ?.childElements
              .map((e) => e.innerText)
              .toList() ??
          <String>[],
      'game': game,
      'settings': settings,
    };
  }
}

// ----------------------------------------------------------------- TXT ----

/// Formato propio legible, líneas `clave=valor`:
///
///     # Circuito Guinda - partida guardada
///     schemaVersion=1
///     name=Mi partida
///     game.tiles=3,5,12,...
///
/// - Líneas vacías y que empiezan por '#' se ignoran.
/// - En valores de texto se escapan `\`, salto de línea y `;`
///   (las etiquetas se separan con `;`).
class TxtSerializer extends SaveSerializer {
  const TxtSerializer();
  @override
  SaveFormat get format => SaveFormat.txt;

  static const _header = '# Circuito Guinda - partida guardada (formato TXT)';

  static String escape(String s) => s
      .replaceAll(r'\', r'\\')
      .replaceAll('\n', r'\n')
      .replaceAll('\r', r'\r')
      .replaceAll(';', r'\;');

  /// Revierte [escape]; si [splitOnSemicolon] devuelve la lista separada
  /// por los `;` no escapados.
  static List<String> unescapeSplit(String s, {bool splitOnSemicolon = false}) {
    final out = <String>[];
    final cur = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == r'\' && i + 1 < s.length) {
        final n = s[++i];
        cur.write(switch (n) { 'n' => '\n', 'r' => '\r', _ => n });
      } else if (c == ';' && splitOnSemicolon) {
        out.add(cur.toString());
        cur.clear();
      } else {
        cur.write(c);
      }
    }
    out.add(cur.toString());
    return out;
  }

  @override
  String encode(SaveGame game) {
    final m = game.toMap();
    final g = m['game'] as Map<String, dynamic>;
    final s = m['settings'] as Map<String, dynamic>;
    final buf = StringBuffer()..writeln(_header);
    buf.writeln('schemaVersion=${m['schemaVersion']}');
    buf.writeln('name=${escape(game.name)}');
    buf.writeln('savedAt=${m['savedAt']}');
    buf.writeln('tags=${game.tags.map(escape).join(';')}');
    buf.writeln();
    buf.writeln('# Estado de la partida');
    for (final e in g.entries) {
      final v = e.value;
      buf.writeln('game.${e.key}=${v is List ? v.join(',') : v}');
    }
    buf.writeln();
    buf.writeln('# Configuración personalizada');
    for (final e in s.entries) {
      buf.writeln('settings.${e.key}=${e.value}');
    }
    return buf.toString();
  }

  @override
  Object? parse(String content) {
    final flat = <String, String>{};
    var lineNo = 0;
    for (final raw in const LineSplitter().convert(content)) {
      lineNo++;
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eq = line.indexOf('=');
      if (eq <= 0) {
        throw CorruptSaveException(
            'Línea $lineNo inválida (se esperaba clave=valor).');
      }
      flat[line.substring(0, eq).trim()] = line.substring(eq + 1);
    }
    if (flat.isEmpty) throw const EmptySaveException();

    Map<String, dynamic>? sub(String prefix) {
      final out = <String, dynamic>{};
      for (final e in flat.entries) {
        if (e.key.startsWith('$prefix.')) {
          out[e.key.substring(prefix.length + 1)] = e.value;
        }
      }
      if (out.isEmpty) return null;
      for (final k in const ['tiles', 'moves']) {
        if (out.containsKey(k)) {
          final v = (out[k] as String).trim();
          out[k] = v.isEmpty ? <String>[] : v.split(',');
        }
      }
      return out;
    }

    final tagsRaw = flat['tags'];
    return {
      'schemaVersion': flat['schemaVersion'],
      'name': flat['name'] == null ? null : unescapeSplit(flat['name']!).first,
      'savedAt': flat['savedAt']?.trim(),
      'tags': (tagsRaw == null || tagsRaw.isEmpty)
          ? <String>[]
          : unescapeSplit(tagsRaw, splitOnSemicolon: true),
      'game': sub('game'),
      'settings': sub('settings'),
    };
  }
}
