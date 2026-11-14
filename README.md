# Práctica 6 · Circuito Guinda

Aplicación Flutter para Android API 24+ e iOS 15+, basada en el gestor de archivos y el juego de la Práctica 4. La meta de este repositorio es que una clonación limpia pueda resolver dependencias y ejecutar la app sin rutas locales ni claves privadas. Flutter/Dart y paquetes quedan fijados en `pubspec.lock`; Gradle obtiene Flutter desde la instalación del desarrollador, como requiere Flutter.

## Arranque rápido · Pixel 4a

Requisitos: Flutter 3.47.9 (Dart 3.13.7), Android Studio con Android SDK instalado, y el AVD llamado exactamente `Pixel_4a` (API 24 o superior). El repositorio no incluye `local.properties`: Flutter lo genera en el primer comando y así cada clon usa su SDK local. Android Studio incluye el JDK requerido.

```bash
git clone <URL-del-repositorio>
cd p6
./scripts/run_pixel4a.sh
```

El script restaura paquetes, inicia el AVD `Pixel_4a` si hace falta, espera el arranque y ejecuta la app. Para compilar manualmente: `flutter pub get && flutter build apk --debug`. El APK queda en `build/app/outputs/flutter-apk/app-debug.apk`. En Android Studio también se puede abrir el directorio y elegir `Pixel_4a`.

## Funciones que ya corren

- Gestor de archivos de Práctica 4: espacio privado, selector del sistema, importación/exportación, favoritos, recientes y visores de texto, JSON, XML e imágenes.
- Juego Circuito Guinda de Práctica 4: modos clásico y reto, partidas guardadas y recuperación de autosave local.
- Pantalla de sensores: acelerómetro (m/s²) y giroscopio (rad/s), lecturas físicas con hora de muestra, frecuencia normal del sistema, aviso de error y cancelación/reinicio de suscripciones al pausar/reanudar. Inclinación registra una interacción visible.
- Temas guinda IPN y azul ESCOM con claro/oscuro del sistema, heredados del gestor.

## Estado de los requisitos de Práctica 6

El gestor y el juego anterior se integraron y la lectura de sensores es real. `flutter analyze`, compilación APK y arranque en el AVD Pixel_4a quedaron verificados. Las funciones nuevas que requieren comunicación entre teléfonos aún están pendientes de implementación: BLE interoperable Android/iOS para juego y transferencia; biometría; y cliente web mediado por Bluetooth. No se declara una sesión física ni evidencia de iOS que no se haya realizado. La arquitectura y matriz de pendientes/pruebas están en [`README for IAS/README.md`](README%20for%20IAS/README.md). Antes de entregar hay que probar con dos equipos, recopilar evidencia real y registrar el resultado por par de dispositivos.

### Arquitectura y decisiones actuales

```text
Flutter UI
├── Gestor P4 (lib/core, lib/features/browser, viewer, library, settings)
├── Circuito Guinda P4 (lib/features/game/{core,game,saves,ui})
└── Sensores (lib/features/sensors)
    └── SensorInterval.normalInterval → sensors_plus → acelerómetro / giroscopio
```

Se reutilizó el gestor y Circuito Guinda de la Práctica 4: navegación, servicios, persistencia, visores y juego local. El gestor usa almacenamiento privado y el juego conserva servicios/autosave JSON propios. La pantalla de sensores se suscribe al abrirse, cancela las suscripciones al pausar y las retoma al reanudar. `sensors_plus` es el adaptador compartido; disponibilidad física debe verificarse en cada equipo.

Se eligió Flutter con UI compartida. `pubspec.lock` fija los paquetes. `android/local.properties` se genera localmente y no se sube; los archivos del Gradle wrapper sí deben quedar versionados para que el clon tenga lo necesario. El AVD local esperado se llama `Pixel_4a`; se probó en emulador, no en un Pixel físico.

### Contrato BLE propuesto (aún no implementado)

Se propone un servicio GATT con característica RX (write/write without response si se negocia) y TX (notify/indicate), con central/periférico adaptados a las capacidades de Android e iOS. El soporte real de roles y anuncio debe comprobarse en hardware; no se debe asumir equivalencia entre sistemas.

Frame JSON UTF-8 propuesto:

```json
{"v":1,"session":"uuid","seq":1,"type":"game.move","requestId":"uuid","payload":{}}
```

`v` es versión; `session`, partida/sesión; `seq`, secuencia creciente por emisor; `type`, tipo permitido; `requestId`, idempotencia; `payload`, datos validados según tipo. El receptor debe rechazar versiones/tipos/campos inválidos, sesiones distintas, secuencias repetidas y acciones fuera de turno. La fragmentación debe basarse en el MTU negociado y llevar id de mensaje, índice, total y ACK, sin fijar tamaño universal. SHA-256 detecta alteraciones, pero no autentica al emisor ni cifra el contenido. Este contrato es solo una propuesta documental, no una función disponible en la app.

### Matriz de pruebas y evidencias

Completar el resultado, dispositivo/versión y evidencia solo después de ejecutar cada caso. No se han hecho pruebas automatizadas ni pruebas con segundo teléfono.

| Caso | Pasos | Resultado esperado | Resultado / dispositivo / evidencia |
|---|---|---|---|
| Acelerómetro y giroscopio disponibles | Abrir Sensores y mover el dispositivo | Lectura física, unidad, instante y estado | AVD Pixel_4a: arranque probado; lectura de hardware pendiente |
| Sensor ausente | Desactivar o simular ausencia | Mensaje informativo, app estable | Pendiente |
| Pausa y reanudación | Enviar la app a segundo plano y volver | Streams detenidos y retomados | Implementado; prueba manual pendiente |
| Permiso denegado | Probar permisos aplicables | Explicación y salida segura | Sensores no requieren permiso móvil; permisos BLE aún no implementados |
| Juego BLE, turno y duplicado | Requiere transporte implementado | Una jugada por secuencia | Pendiente |
| TXT/JSON/XML/JPG y archivo grande | Requiere transferencia BLE | Integridad antes de guardar final | Pendiente |
| Hash incorrecto, cancelar y desconectar | Requiere transferencia BLE | Temporal descartado; estado fallido/cancelado | Pendiente |
| Consulta web con B sin Internet | Requiere proxy BLE en A | Red solo a través de A; caché identificada | Pendiente |
| Android en Pixel 4a | Ejecutar `./scripts/run_pixel4a.sh` | Instala y abre la app | Verificado en AVD Pixel_4a de este equipo; físico pendiente |
| iOS | Compilar y ejecutar con Xcode | Evidencia real en iOS 15+ | No verificado |

### Pendientes para completar la práctica

1. Implementar biometría del sistema al proteger una acción sensible del gestor, con alternativa adecuada.
2. Implementar BLE GATT Android/iOS, negociación de roles/MTU y protocolo versionado, secuenciado y deduplicado para partidas.
3. Implementar transferencia TXT, JSON, XML y JPG: aceptación explícita, metadatos, límite, bloques/ACK, progreso, cancelación, archivo temporal, SHA-256 e historial persistente.
4. Implementar cliente HTTPS mediado por Bluetooth con lista de dominios permitidos, validación de redirecciones y bloqueo de destinos locales/privados; límite de bytes, duración y solicitudes, historial, favoritos y caché.
5. Añadir pruebas de lógica/protocolo; cubrir sensores disponibles/ausentes, ciclo de vida, permisos, desconexión, duplicados, formatos e integridad.
6. Completar pruebas y evidencia en dos dispositivos físicos, registrar pares Android/iOS realmente probados y obtener evidencia de ejecución iOS con Xcode. No afirmar conectividad o hardware no comprobados.

### Registro de verificación y asistencia

- `flutter analyze`: sin incidencias.
- `flutter build apk --debug`: exitoso; artefacto local en `build/app/outputs/flutter-apk/app-debug.apk` (no se incluye en el repositorio).
- `./scripts/run_pixel4a.sh`: compiló, instaló y abrió la app en el AVD `Pixel_4a` de este equipo.
- `flutter test`: no ejecutado en este avance.
- iOS y dispositivos físicos: no verificados.
- Se usó asistencia de IA para integrar la fuente de la Práctica 4, añadir la pantalla de sensores y preparar configuración/documentación. El estudiante debe revisar el código, ejecutar las pruebas pendientes y reportar cualquier error encontrado.

## Plataformas

- Android: `minSdk 24`; no se solicitan permisos de almacenamiento global. Los documentos externos se eligen con el selector del sistema.
- iOS: despliegue mínimo 15.0 configurado por Flutter. El arranque aquí no sustituye una compilación y verificación real con Xcode.
- Bluetooth todavía no está habilitado; por ello el manifiesto no pide permisos Bluetooth ni ubicación innecesarios.

## Desarrollo

```bash
flutter pub get
flutter analyze
flutter test
```

Flutter 3.47.9 / Dart 3.13.7. Dependencias directas adicionales a Flutter SDK: `file_picker 13.3.2`, `sensors_plus 7.1.1`, `audioplayers 6.8.1`, `path_provider 2.1.6`, `share_plus 13.3.1`, `shared_preferences 2.5.6`, `xml 7.1.0`, `image 4.12.0`, `mime 2.1.0`, `open_filex 5.0.0`, `intl 0.20.3`, `path 1.9.1`. `pubspec.lock` es la referencia completa reproducible.

## English

Flutter app for Android 24+ and iOS 15+, combining the Practice 4 file manager and Circuito Guinda game with physical accelerometer and gyroscope readings. For a clean Android checkout, install Flutter 3.47.9, Android Studio/SDK, and an AVD named `Pixel_4a`, then run `./scripts/run_pixel4a.sh`. Dependencies are locked in `pubspec.lock`; machine-specific SDK paths and signing keys are not committed.

The Practice 6 BLE multiplayer/file transfer, biometric protection, and Bluetooth-relayed HTTPS client are not implemented yet. No physical-device or iOS result is claimed. See [`README for IAS/README.md`](README%20for%20IAS/README.md) for architecture, protocol proposal, limitations, and the verification matrix.

## Uso de IA

Se usó asistencia de IA para integrar código de la Práctica 4, añadir la pantalla de sensores y redactar configuración/documentación inicial. Se verificará con análisis, pruebas automatizadas y compilación; los resultados pendientes se deben completar y declarar por quien entregue.
