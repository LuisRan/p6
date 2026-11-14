/// Jerarquía de excepciones propias del sistema de guardado.
///
/// Todas llevan un [message] en español apto para mostrarse al usuario.
sealed class SaveException implements Exception {
  const SaveException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Archivo vacío o solo con espacios.
class EmptySaveException extends SaveException {
  const EmptySaveException() : super('El archivo está vacío.');
}

/// Contenido ilegible o con sintaxis inválida para el formato.
class CorruptSaveException extends SaveException {
  const CorruptSaveException(super.message);
}

/// Faltan campos obligatorios (archivo truncado o incompleto).
class IncompleteSaveException extends SaveException {
  const IncompleteSaveException(String field)
      : super('Archivo incompleto: falta el campo "$field".');
}

/// Versión de esquema desconocida (más nueva que la soportada).
class UnsupportedVersionException extends SaveException {
  UnsupportedVersionException(int found, int supported)
      : super('Versión de esquema $found no soportada '
            '(esta app entiende hasta la $supported).');
}

/// Error de E/S del sistema de archivos.
class SaveIoException extends SaveException {
  const SaveIoException(super.message);
}
