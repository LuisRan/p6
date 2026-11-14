import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestor_archivos/core/errors/app_exception.dart';
import 'package:gestor_archivos/core/services/file_service.dart';
import 'package:gestor_archivos/core/services/seed_data.dart';
import 'package:gestor_archivos/core/services/thumbnail_cache.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  final svc = FileService();
  setUp(() => tmp = Directory.systemTemp.createTempSync('gestor_test'));
  tearDown(() => tmp.deleteSync(recursive: true));

  File mk(String name, [String c = 'hola']) => File(p.join(tmp.path, name))..writeAsStringSync(c);

  test('list: carpetas primero y ordenado; oculta dotfiles', () async {
    mk('b.txt'); mk('A.txt'); mk('.oculto');
    Directory(p.join(tmp.path, 'zdir')).createSync();
    final l = await svc.list(tmp.path);
    expect(l.map((e) => e.name), ['zdir', 'A.txt', 'b.txt']);
  });

  test('list en ruta inexistente lanza notFound', () async {
    expect(svc.list(p.join(tmp.path, 'nada')),
        throwsA(isA<AppException>().having((e) => e.kind, 'kind', FailureKind.notFound)));
  });

  test('rename valida nombre y colisiones', () async {
    final f = mk('a.txt'); mk('b.txt');
    expect(svc.rename(f.path, 'x/y'), throwsA(isA<AppException>()));
    expect(svc.rename(f.path, 'b.txt'),
        throwsA(isA<AppException>().having((e) => e.kind, 'k', FailureKind.alreadyExists)));
    final np = await svc.rename(f.path, 'c.txt');
    expect(File(np).existsSync(), isTrue);
    expect(f.existsSync(), isFalse);
  });

  test('copy genera nombre único y reporta progreso', () async {
    final f = mk('a.txt', 'x' * 1000);
    final fr = <double>[];
    final out = await svc.copy(f.path, tmp.path, onProgress: fr.add);
    expect(p.basename(out), 'a (1).txt');
    expect(fr.last, 1);
    expect(File(out).readAsStringSync(), 'x' * 1000);
  });

  test('copy de carpeta recursiva y rechazo dentro de sí misma', () async {
    final d = Directory(p.join(tmp.path, 'd'))..createSync();
    File(p.join(d.path, 'f.txt')).writeAsStringSync('1');
    final dest = Directory(p.join(tmp.path, 'dest'))..createSync();
    final out = await svc.copy(d.path, dest.path);
    expect(File(p.join(out, 'f.txt')).existsSync(), isTrue);
    expect(svc.copy(d.path, d.path), throwsA(isA<AppException>()));
  });

  test('move y destino inexistente', () async {
    final f = mk('a.txt');
    final dest = Directory(p.join(tmp.path, 'dest'))..createSync();
    final out = await svc.move(f.path, dest.path);
    expect(File(out).existsSync(), isTrue);
    expect(f.existsSync(), isFalse);
    expect(svc.move(out, p.join(tmp.path, 'no')),
        throwsA(isA<AppException>().having((e) => e.kind, 'k', FailureKind.notFound)));
  });

  test('delete y archivo inexistente', () async {
    final f = mk('a.txt');
    await svc.delete(f.path);
    expect(f.existsSync(), isFalse);
    expect(svc.delete(f.path), throwsA(isA<AppException>()));
  });

  test('metadata: MIME, tamaño y creación no disponible', () async {
    final f = mk('a.json', '{}');
    final m = await svc.metadata(f.path);
    expect(m.mime, 'application/json');
    expect(m.utType, 'public.json');
    expect(m.size, 2);
    expect(m.created, isNull);
  });

  test('readText trunca archivos grandes', () async {
    final f = mk('big.txt', 'a' * 5000);
    final (t, trunc) = await svc.readText(f.path, maxBytes: 1000);
    expect(t.length, 1000);
    expect(trunc, isTrue);
  });

  test('SeedData crea ejemplos y es idempotente', () async {
    await SeedData.seed(tmp);
    await SeedData.seed(tmp);
    final names = tmp.listSync(recursive: true).whereType<File>().map((f) => p.basename(f.path)).toSet();
    expect(names, containsAll(['nota.txt', 'lee_me.md', 'alumnos.json', 'plan.xml', 'degradado.png', 'datos.bin']));
  });

  test('ThumbnailCache genera miniatura y respeta el límite', () async {
    await SeedData.seed(tmp);
    final png = File(p.join(tmp.path, 'Ejemplos', 'Imagenes', 'degradado.png'));
    final cache = ThumbnailCache(Directory(p.join(tmp.path, 'c')), maxBytes: 1);
    final t = await cache.thumbnailFor(png);
    expect(t, isNotNull);
    await cache.evict();
    expect(await cache.sizeOnDisk(), 0); // límite de 1 byte => expulsada
  });
}
