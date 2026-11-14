import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_archivos/core/services/syntax_highlighter.dart';
import 'package:gestor_archivos/core/utils/formatters.dart';

void main() {
  const json = '{"a": [1, 2.5, true, null], "b": "x"}';
  test('JSON: tokens reconstruyen el texto original', () {
    final t = SyntaxHighlighter.tokenizeJson(json);
    expect(t.map((e) => e.text).join(), json);
  });
  test('JSON: clasifica claves, cadenas, números y literales', () {
    final t = SyntaxHighlighter.tokenizeJson(json);
    expect(t.where((e) => e.type == TokenType.key).map((e) => e.text), ['"a"', '"b"']);
    expect(t.where((e) => e.type == TokenType.string).map((e) => e.text), ['"x"']);
    expect(t.where((e) => e.type == TokenType.number).map((e) => e.text), ['1', '2.5']);
    expect(t.where((e) => e.type == TokenType.keyword).map((e) => e.text), ['true', 'null']);
  });
  const xml = '<?xml version="1.0"?><!-- c --><r a="1"><x b=\'2\'/>hola</r>';
  test('XML: tokens reconstruyen el texto original', () {
    final t = SyntaxHighlighter.tokenizeXml(xml);
    expect(t.map((e) => e.text).join(), xml);
  });
  test('XML: etiquetas, atributos y comentarios', () {
    final t = SyntaxHighlighter.tokenizeXml(xml);
    expect(t.where((e) => e.type == TokenType.comment).length, 1);
    expect(t.where((e) => e.type == TokenType.attrName).map((e) => e.text), ['a', 'b']);
    expect(t.where((e) => e.type == TokenType.attrValue).map((e) => e.text), ['"1"', "'2'"]);
    expect(t.where((e) => e.type == TokenType.tag).map((e) => e.text), contains('<r'));
  });
  test('prettyJson / prettyXml', () {
    expect(prettyJson('{"a":[1,2]}'), '{\n  "a": [\n    1,\n    2\n  ]\n}');
    expect(prettyXml('<a><b>1</b></a>'), contains('\n  <b>1</b>'));
    expect(() => prettyJson('{oops'), throwsFormatException);
    expect(() => prettyXml('<a>'), throwsFormatException);
  });
  test('formatBytes y formatDate', () {
    expect(formatBytes(null), 'No disponible');
    expect(formatBytes(500), '500 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(5 * 1024 * 1024), '5.0 MB');
    expect(formatDate(null), 'No disponible');
    expect(formatDate(DateTime(2026, 1, 2, 3, 4)), '02/01/2026 03:04');
  });
}
