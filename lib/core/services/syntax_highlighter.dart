import 'package:flutter/painting.dart';

/// Categorías de token; el color se decide al construir los TextSpan.
enum TokenType { plain, key, string, number, keyword, punct, tag, attrName, attrValue, comment }

class Token {
  const Token(this.text, this.type);
  final String text;
  final TokenType type;
  @override
  String toString() => '$type:$text';
}

/// Highlighter propio (sin paquetes) para JSON y XML. Es lógica pura:
/// la concatenación de los tokens siempre reproduce el texto original.
class SyntaxHighlighter {
  // JSON: cadena (con posible ':' posterior => clave), número, literal, puntuación.
  static final _json = RegExp(
    r'("(?:\\.|[^"\\])*")(\s*:)?|(-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?)|\b(true|false|null)\b|([{}\[\],:])',
  );

  static List<Token> tokenizeJson(String src) {
    final out = <Token>[];
    var last = 0;
    for (final m in _json.allMatches(src)) {
      if (m.start > last) out.add(Token(src.substring(last, m.start), TokenType.plain));
      if (m.group(1) != null) {
        if (m.group(2) != null) {
          out.add(Token(m.group(1)!, TokenType.key));
          out.add(Token(m.group(2)!, TokenType.punct));
        } else {
          out.add(Token(m.group(1)!, TokenType.string));
        }
      } else if (m.group(3) != null) {
        out.add(Token(m.group(3)!, TokenType.number));
      } else if (m.group(4) != null) {
        out.add(Token(m.group(4)!, TokenType.keyword));
      } else {
        out.add(Token(m.group(5)!, TokenType.punct));
      }
      last = m.end;
    }
    if (last < src.length) out.add(Token(src.substring(last), TokenType.plain));
    return out;
  }

  // XML: comentarios, PI/declaraciones, CDATA y etiquetas completas.
  static final _xmlMarkup = RegExp(
    r'''<!--[\s\S]*?-->|<!\[CDATA\[[\s\S]*?\]\]>|<\?[\s\S]*?\?>|<![\s\S]*?>|</?[^\s<>/!?](?:"[^"]*"|'[^']*'|[^<>"'])*>''',
  );
  static final _tagName = RegExp(r'^</?[^\s/>]+');
  static final _attr = RegExp(r'''([^\s=/<>]+)(\s*=\s*)("[^"]*"|'[^']*')''');

  static List<Token> tokenizeXml(String src) {
    final out = <Token>[];
    var last = 0;
    for (final m in _xmlMarkup.allMatches(src)) {
      if (m.start > last) out.add(Token(src.substring(last, m.start), TokenType.plain));
      final s = m.group(0)!;
      if (s.startsWith('<!--') || s.startsWith('<![CDATA[')) {
        out.add(Token(s, TokenType.comment));
      } else if (s.startsWith('<?') || s.startsWith('<!')) {
        out.add(Token(s, TokenType.keyword));
      } else {
        final nm = _tagName.firstMatch(s)!;
        out.add(Token(nm.group(0)!, TokenType.tag));
        var pos = nm.end;
        final endsSelf = s.endsWith('/>');
        final closeLen = endsSelf ? 2 : 1;
        final body = s.substring(pos, s.length - closeLen);
        var bl = 0;
        for (final a in _attr.allMatches(body)) {
          if (a.start > bl) out.add(Token(body.substring(bl, a.start), TokenType.plain));
          out.add(Token(a.group(1)!, TokenType.attrName));
          out.add(Token(a.group(2)!, TokenType.punct));
          out.add(Token(a.group(3)!, TokenType.attrValue));
          bl = a.end;
        }
        if (bl < body.length) out.add(Token(body.substring(bl), TokenType.plain));
        out.add(Token(s.substring(s.length - closeLen), TokenType.tag));
      }
      last = m.end;
    }
    if (last < src.length) out.add(Token(src.substring(last), TokenType.plain));
    return out;
  }

  /// Convierte tokens en TextSpan usando una paleta (distinta en claro/oscuro).
  static TextSpan toSpan(List<Token> tokens, Map<TokenType, Color> palette, TextStyle base) {
    return TextSpan(
      style: base,
      children: [
        for (final t in tokens)
          TextSpan(
            text: t.text,
            style: palette[t.type] == null ? null : TextStyle(color: palette[t.type]),
          ),
      ],
    );
  }

  static Map<TokenType, Color> palette(bool dark) => dark
      ? const {
          TokenType.key: Color(0xFF9CDCFE),
          TokenType.string: Color(0xFFCE9178),
          TokenType.number: Color(0xFFB5CEA8),
          TokenType.keyword: Color(0xFFC586C0),
          TokenType.punct: Color(0xFF9E9E9E),
          TokenType.tag: Color(0xFF4EC9B0),
          TokenType.attrName: Color(0xFF9CDCFE),
          TokenType.attrValue: Color(0xFFCE9178),
          TokenType.comment: Color(0xFF6A9955),
        }
      : const {
          TokenType.key: Color(0xFF0B3C8C),
          TokenType.string: Color(0xFFA31515),
          TokenType.number: Color(0xFF098658),
          TokenType.keyword: Color(0xFF7A1E3F),
          TokenType.punct: Color(0xFF616161),
          TokenType.tag: Color(0xFF800000),
          TokenType.attrName: Color(0xFFE50000),
          TokenType.attrValue: Color(0xFF0451A5),
          TokenType.comment: Color(0xFF008000),
        };
}
