/// Tipos de fallo que la UI sabe explicar al usuario sin mostrar trazas.
enum FailureKind {
  notFound, // ruta/archivo inexistente o carpeta ya no disponible
  permissionDenied, // permiso revocado o nunca concedido
  noSpace, // disco lleno
  readFailed, // lectura fallida / formato corrupto
  invalidDestination, // destino inválido (p. ej. mover carpeta dentro de sí misma)
  alreadyExists, // colisión de nombres
  invalidName, // nombre con caracteres no permitidos
  unknown,
}

/// Excepción de dominio con mensaje legible en español.
class AppException implements Exception {
  AppException(this.kind, this.message, {this.path});
  final FailureKind kind;
  final String message;
  final String? path;

  @override
  String toString() => 'AppException($kind): $message';
}
