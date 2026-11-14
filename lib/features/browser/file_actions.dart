import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';

import '../../core/errors/app_exception.dart';
import '../../core/services/file_service.dart';
import '../../core/utils/formatters.dart';
import '../../main.dart';
import '../viewer/viewer_page.dart';

/// Muestra un error de forma amigable (SnackBar) sin propagar excepciones.
void showFailure(BuildContext context, Object e) {
  if (!context.mounted) return;
  final msg = e is AppException ? e.message : 'Ocurrió un error: $e';
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Theme.of(context).colorScheme.error,
      behavior: SnackBarBehavior.floating,
    ));
}

void showInfo(BuildContext context, String msg) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
}

/// Confirmación para acciones destructivas.
Future<bool> confirm(BuildContext context,
    {required String title, required String body, String action = 'Eliminar'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(action)),
      ],
    ),
  );
  return r ?? false;
}

Future<String?> askText(BuildContext context,
    {required String title, String initial = '', String action = 'Aceptar'}) {
  final ctrl = TextEditingController(text: initial);
  ctrl.selection = TextSelection(baseOffset: 0, extentOffset: p.basenameWithoutExtension(initial).length);
  return showDialog<String>(
    context: context,
    builder: (c) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctrl, autofocus: true, onSubmitted: (v) => Navigator.pop(c, v)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(c, ctrl.text), child: Text(action)),
      ],
    ),
  );
}

/// Ejecuta [job] mostrando un diálogo con barra de progreso (determinada si
/// el trabajo reporta fracción). Devuelve null si falló (ya se mostró el error).
Future<T?> runWithProgress<T>(
  BuildContext context,
  String title,
  Future<T> Function(ProgressCallback report) job,
) async {
  final progress = ValueNotifier<double?>(null);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (c) => PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(title),
        content: ValueListenableBuilder<double?>(
          valueListenable: progress,
          builder: (_, v, _) => Column(mainAxisSize: MainAxisSize.min, children: [
            LinearProgressIndicator(value: v),
            const SizedBox(height: 8),
            Text(v == null ? 'Trabajando…' : '${(v * 100).round()} %'),
          ]),
        ),
      ),
    ),
  );
  try {
    return await job((f) => progress.value = f);
  } catch (e) {
    if (context.mounted) showFailure(context, e);
    return null;
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
    progress.dispose();
  }
}

/// Diálogo de metadatos; los datos ausentes se muestran como "No disponible".
Future<void> showMetadata(BuildContext context, AppServices s, String path) async {
  try {
    final m = await s.files.metadata(path);
    if (!context.mounted) return;
    Widget row(String k, String? v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 110, child: Text(k, style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(child: SelectableText(v ?? 'No disponible')),
          ]),
        );
    await showDialog<void>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Propiedades'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            row('Nombre', m.name),
            row('Ruta', m.path),
            row('Tipo', m.isDirectory ? 'Carpeta' : 'Archivo'),
            row('Tamaño', m.size == null ? null : formatBytes(m.size)),
            row('Creación', m.created == null ? null : formatDate(m.created)),
            row('Modificación', m.modified == null ? null : formatDate(m.modified)),
            row('MIME', m.mime),
            row('UTType (iOS)', m.utType),
          ]),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar'))],
      ),
    );
  } catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}

Future<void> shareFile(BuildContext context, String path) async {
  try {
    if (!await File(path).exists()) {
      throw AppException(FailureKind.notFound, 'El archivo ya no existe.');
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(path)]));
  } catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}

/// Exporta con el selector "Guardar como" del sistema (SAF / Archivos).
Future<void> exportFile(BuildContext context, String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    final r = await FilePicker.saveFile(fileName: p.basename(path), bytes: bytes);
    if (r != null && context.mounted) showInfo(context, 'Archivo exportado.');
  } catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}

Future<void> openExternally(BuildContext context, String path) async {
  try {
    final r = await OpenFilex.open(path);
    if (r.type != ResultType.done && context.mounted) {
      showInfo(context, 'No hay aplicación para abrir este archivo (${r.message}).');
    }
  } catch (e) {
    if (context.mounted) showFailure(context, e);
  }
}

/// Diálogo para formatos no soportados por el visor interno.
Future<void> showUnsupportedDialog(BuildContext context, String path) {
  return showDialog<void>(
    context: context,
    builder: (c) => AlertDialog(
      icon: const Icon(Icons.help_outline),
      title: const Text('Formato no soportado'),
      content: Text('"${p.basename(path)}" no se puede mostrar en la app. '
          'Puedes abrirlo con otra aplicación, compartirlo o exportarlo.'),
      actions: [
        TextButton(onPressed: () { Navigator.pop(c); openExternally(context, path); }, child: const Text('Abrir con…')),
        TextButton(onPressed: () { Navigator.pop(c); shareFile(context, path); }, child: const Text('Compartir')),
        TextButton(onPressed: () { Navigator.pop(c); exportFile(context, path); }, child: const Text('Exportar')),
        TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cerrar')),
      ],
    ),
  );
}

/// Punto de entrada único para abrir un archivo: registra reciente y despacha.
Future<void> openFileEntry(BuildContext context, AppServices s, String path) async {
  if (!await File(path).exists()) {
    if (context.mounted) {
      showFailure(context, AppException(FailureKind.notFound, 'El archivo ya no existe o su carpeta no está disponible.'));
    }
    await s.prefs.forget(path);
    return;
  }
  await s.prefs.addRecent(path);
  if (!context.mounted) return;
  final kind = ViewerKind.fromPath(path);
  if (kind == ViewerKind.unsupported) {
    await showUnsupportedDialog(context, path);
  } else {
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ViewerPage(services: s, path: path, kind: kind),
    ));
  }
}
