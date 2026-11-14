import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'save_exceptions.dart';
import 'save_repository.dart';

/// Operaciones con el sistema de archivos del dispositivo.
///
/// - Exportar: `FilePicker.saveFile` abre el selector nativo
///   (Storage Access Framework en Android, UIDocumentPicker en iOS).
/// - Compartir: hoja nativa vía `share_plus`.
/// - Importar: `FilePicker.pickFile` (SAF / UIDocumentPicker); el contenido
///   se lee en memoria y se valida antes de copiarlo a `saves/`.
class FileActions {
  const FileActions(this.repo);
  final SaveRepository repo;

  /// Devuelve true si el usuario eligió destino y se escribió el archivo.
  Future<bool> export(SaveEntry e) async {
    final bytes = await e.file.readAsBytes();
    final uri = await FilePicker.saveFile(
      dialogTitle: 'Exportar partida',
      fileName: e.fileName,
      bytes: bytes,
      mimeType: e.format.mimeType,
    );
    return uri != null;
  }

  Future<void> share(SaveEntry e, {Rect? origin}) async {
    await SharePlus.instance.share(ShareParams(
      files: [XFile(e.file.path, mimeType: e.format.mimeType)],
      subject: 'Partida: ${e.displayName}',
      text: 'Partida de Circuito Guinda: ${e.displayName}',
      sharePositionOrigin: origin,
    ));
  }

  /// Importa un archivo elegido por el usuario. Devuelve el archivo creado
  /// o null si canceló. Lanza [SaveException] si el contenido no es válido.
  Future<File?> importFromPicker() async {
    final picked = await FilePicker.pickFile(
      dialogTitle: 'Importar partida (.txt, .xml, .json)',
    );
    if (picked == null) return null;
    final bytes = await picked.readAsBytes();
    final text = utf8.decode(bytes, allowMalformed: true);
    return repo.importContent(text, picked.name);
  }
}
