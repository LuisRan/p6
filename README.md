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
- Pantalla de sensores: acelerómetro (m/s²) y giroscopio (rad/s), lecturas reportadas por el sistema con instante, frecuencia normal, aviso de error y cancelación/reinicio de suscripciones al pausar/reanudar. La app aclara que el emulador puede simular valores. Inclinación registra una interacción visible.
- Protección biométrica del borrado: usa el diálogo de autenticación del sistema mediante `local_auth`, con huella y credencial de pantalla como alternativa.
- Consulta web en modo de simulación: presenta roles B/A, allowlist, estado, tiempo, historial, favoritos y caché usando respuestas locales de ejemplo; no ejecuta HTTPS ni Bluetooth.
- Temas guinda IPN y azul ESCOM con claro/oscuro del sistema, heredados del gestor.

## Evidencia de ejecución

Capturas tomadas el 15 de noviembre de 2026 desde Android Studio Emulator, AVD `Pixel_4a` (1080×2340). Se revisó cada PNG para confirmar que muestra la pantalla completa, sin carga pendiente ni error. Son evidencia de ejecución en el emulador; los valores de sensores que reporta el AVD pueden ser simulados.

### Gestor y visores

![Gestor de archivos en Documentos de la app](evidencias/01_archivos.png)

![Carpeta de ejemplos](evidencias/02_archivos_ejemplos.png)

![Archivos JSON, Markdown, TXT y XML disponibles en el gestor](evidencias/03_documentos_formatos.png)

![Visor de Markdown](evidencias/04_visor_texto.png)

![Visor con formato y resaltado JSON](evidencias/13_visor_json.png)

![Visor con formato y resaltado XML](evidencias/15_visor_xml.png)

![Carpeta de imágenes del gestor](evidencias/10_imagenes.png)

![Visor de imagen con control de rotación](evidencias/11_visor_imagen.png)

### Temas y sensores

![Selector de temas Guinda IPN y Azul ESCOM](evidencias/14_ajustes_tema.png)

![Acelerómetro y giroscopio reportados por el AVD, con unidades e instante](evidencias/05_sensores.png)

### Juego local de Práctica 4

![Menú de Circuito Guinda](evidencias/06_juego_local.png)

![Tablero de una partida local](evidencias/07_partida_local.png)

![Partida local después de girar una pieza; contador de movimientos actualizado](evidencias/08_movimiento_local.png)

Estas pantallas prueban los flujos locales disponibles. **No demuestran** una partida sincronizada por Bluetooth, transferencia entre dispositivos ni una consulta web que viaje por un relay Bluetooth real; esos transportes siguen pendientes.

### Biometría y consulta web simulada en Android

Recorrido en el AVD `Pixel_4a` de Android Studio (Android 17/API 37). Se enroló la huella virtual del emulador y se configuró el PIN del dispositivo como alternativa. La autenticación del sistema protege la acción de eliminar; el AVD aprobó el flujo con la huella virtual. Android oculta el diálogo biométrico en las capturas del sistema, por eso se incluye la confirmación previa y el estado posterior a la autorización.

![Consulta HTTPS de ejemplo entregada por el relay A simulado](evidencias/16_consulta_web_respuesta.png)

![Respuesta identificada como caché cuando el relay A simulado queda sin conexión](evidencias/17_consulta_web_cache.png)

![Confirmación de borrado que informa que después solicitará huella o credencial del dispositivo](evidencias/18_biometria_confirmacion.png)

![Lista de archivos después de autorizar el borrado con la huella virtual del AVD](evidencias/19_biometria_autorizada.png)

La vista web usa fixtures locales para dos rutas HTTPS de JSONPlaceholder y rechaza otros destinos. El estado “A sin Internet” sirve para demostrar el uso de caché en esta simulación; **no** equivale a peticiones HTTPS reales ni a comunicación B→A por Bluetooth.

### Simulador iOS

La app también se ejecutó en iPhone 17 Simulator con iOS 27.2 usando Xcode 27.2. Para estas capturas se usó temporalmente `integration_test`; tanto la prueba como sus dependencias temporales se retiraron después. El simulador no entregó lecturas de acelerómetro/giroscopio, así que la pantalla muestra el estado de ausencia de datos.

![Gestor de archivos ejecutándose en iPhone 17 Simulator](evidencias/ios/ios_archivos.png)

![Estado sin lecturas de sensores en el simulador iOS](evidencias/ios/ios_sensores.png)

![Consulta web simulada en iOS con respuesta 200 y JSON local](evidencias/ios/ios_web_respuesta.png)

![Consulta web simulada en iOS recuperada desde caché con A desconectado](evidencias/ios/ios_web_cache.png)

![Menú de Circuito Guinda en iPhone 17 Simulator](evidencias/ios/ios_juego.png)

![Tablero local de Circuito Guinda en iPhone 17 Simulator](evidencias/ios/ios_partida_local.png)

## Estado de los requisitos de Práctica 6

El gestor y el juego anterior se integraron y la lectura de sensores está conectada al sistema. `flutter analyze`, compilación APK y arranque en el AVD Pixel_4a quedaron verificados. La app también compiló y se recorrió en el simulador iPhone 17 de Xcode 27.2; allí se verificaron los flujos web de respuesta y caché. La biometría para eliminar está implementada y verificada en el AVD Android; la autorización Face ID en iOS queda pendiente de probar en un iPhone porque este entorno no incluye la app gráfica Simulator para enrolar/confirmar Face ID. La consulta web disponible es una simulación local; faltan el relay HTTPS real por BLE, el juego sincronizado y la transferencia entre dispositivos. La arquitectura y matriz de pendientes están en [`README for IAS/README.md`](README%20for%20IAS/README.md).

### Arquitectura y decisiones actuales

```text
Flutter UI
├── Gestor P4 (lib/core, lib/features/browser, viewer, library, settings)
├── Circuito Guinda P4 (lib/features/game/{core,game,saves,ui})
├── Sensores (lib/features/sensors) → sensors_plus
├── Protección del borrado → local_auth
└── Consulta web simulada (lib/features/web) → fixtures HTTPS locales; relay BLE pendiente
```

Se reutilizó el gestor y Circuito Guinda de la Práctica 4: navegación, servicios, persistencia, visores y juego local. El gestor usa almacenamiento privado y el juego conserva servicios/autosave JSON propios. La pantalla de sensores se suscribe al abrirse, cancela las suscripciones al pausar y las retoma al reanudar. `sensors_plus` es el adaptador compartido; en el AVD los valores reportados pueden ser simulados.

Se eligió Flutter con UI compartida. `pubspec.lock` fija los paquetes. `android/local.properties` se genera localmente y no se sube; los archivos del Gradle wrapper sí deben quedar versionados para que el clon tenga lo necesario. El AVD local esperado se llama `Pixel_4a`; la ejecución documentada se hizo en Android Studio Emulator.

### Contrato BLE propuesto (aún no implementado)

Se propone un servicio GATT con característica RX (write/write without response si se negocia) y TX (notify/indicate), con central/periférico adaptados a las capacidades de Android e iOS. El soporte real de roles y anuncio debe comprobarse en hardware; no se debe asumir equivalencia entre sistemas.

Frame JSON UTF-8 propuesto:

```json
{"v":1,"session":"uuid","seq":1,"type":"game.move","requestId":"uuid","payload":{}}
```

`v` es versión; `session`, partida/sesión; `seq`, secuencia creciente por emisor; `type`, tipo permitido; `requestId`, idempotencia; `payload`, datos validados según tipo. El receptor debe rechazar versiones/tipos/campos inválidos, sesiones distintas, secuencias repetidas y acciones fuera de turno. La fragmentación debe basarse en el MTU negociado y llevar id de mensaje, índice, total y ACK, sin fijar tamaño universal. SHA-256 detecta alteraciones, pero no autentica al emisor ni cifra el contenido. Este contrato es solo una propuesta documental, no una función disponible en la app.

### Matriz de pruebas y evidencias

Completar el resultado, dispositivo/versión y evidencia solo después de ejecutar cada caso. No se ejecutaron las pruebas automatizadas permanentes ni pruebas con segundo teléfono; sí se usó una prueba temporal para capturar flujos en el simulador iOS y luego se eliminó.

| Caso | Pasos | Resultado esperado | Resultado / dispositivo / evidencia |
|---|---|---|---|
| Acelerómetro y giroscopio disponibles | Abrir Sensores y observar valores | Lectura, unidad, instante y estado; distinguir valores simulados | AVD Pixel_4a reportó valores; evidencia en `evidencias/05_sensores.png` |
| Sensor ausente | Abrir Sensores en simulador iOS | Mensaje informativo, app estable | iPhone 17 Simulator: sin lecturas, aviso de ausencia verificado |
| Pausa y reanudación | Enviar la app a segundo plano y volver | Streams detenidos y retomados | Implementado; prueba manual pendiente |
| Permiso denegado | Probar permisos aplicables | Explicación y salida segura | Sensores no requieren permiso móvil; permisos BLE aún no implementados |
| Borrado protegido por biometría | Eliminar un archivo de ejemplo y autenticar | El sistema autoriza con huella o credencial alternativa | Android AVD Pixel_4a: huella virtual aceptada; evidencia `18`/`19`. iOS: Face ID pendiente en iPhone real; el build del simulador no valida autenticación exitosa |
| Juego BLE, turno y duplicado | Requiere transporte implementado | Una jugada por secuencia | Pendiente |
| TXT/JSON/XML/JPG y archivo grande | Requiere transferencia BLE | Integridad antes de guardar final | Pendiente |
| Hash incorrecto, cancelar y desconectar | Requiere transferencia BLE | Temporal descartado; estado fallido/cancelado | Pendiente |
| Consulta web simulada con A disponible/sin conexión | Consultar el fixture y desconectar A | Estado, ID, tiempo y caché identificada | Android AVD: capturas `16`/`17`; iPhone 17 Simulator: `evidencias/ios/ios_web_respuesta.png` y `ios_web_cache.png` |
| Consulta web real con B sin Internet | Requiere proxy HTTPS por BLE en A | Red solo a través de A; caché identificada | Pendiente; la pantalla actual usa fixtures locales y no BLE |
| Android en Pixel 4a | Ejecutar `./scripts/run_pixel4a.sh` | Instala y abre la app | Verificado en AVD Pixel_4a de este equipo |
| iOS | Ejecutar en iPhone 17 Simulator | UI compartida inicia y muestra pantallas | Xcode 27.2 / iOS 27.2; gestor, juego, sensores, consulta web y caché capturados. Face ID real pendiente en iPhone |

### Pendientes para completar la práctica

1. Implementar BLE GATT Android/iOS, negociación de roles/MTU y protocolo versionado, secuenciado y deduplicado para partidas.
2. Implementar transferencia TXT, JSON, XML y JPG: aceptación explícita, metadatos, límite, bloques/ACK, progreso, cancelación, archivo temporal, SHA-256 e historial persistente.
3. Conectar la vista web al relay HTTPS por BLE y hacer peticiones de red reales desde A; conservar validación de allowlist/redirecciones, límites, historial, favoritos y caché.
4. Añadir pruebas de lógica/protocolo; cubrir sensores disponibles/ausentes, ciclo de vida, rechazo/cancelación biométrica, desconexión BLE, duplicados, formatos e integridad.
5. Cuando se implemente BLE, completar pruebas de interoperabilidad entre dispositivos Android/iOS y registrar los pares y resultados.

### Registro de verificación y asistencia

- `flutter analyze`: sin incidencias.
- `flutter build apk --debug`: exitoso; artefacto local en `build/app/outputs/flutter-apk/app-debug.apk` (no se incluye en el repositorio).
- Biometría: en AVD Pixel_4a Android 17 se configuró PIN de dispositivo, se enroló la huella virtual y `local_auth` autorizó el borrado de un archivo.
- Web simulada: se recorrió respuesta JSON con estado 200/ID/tiempo y recuperación etiquetada desde caché con el relay A apagado.
- `./scripts/run_pixel4a.sh`: compiló, instaló y abrió la app en el AVD `Pixel_4a` de este equipo. En la prueba manual se recorrieron gestor, ejemplos, visor Markdown, visor JSON, visor de imagen, ajustes de tema, sensores, menú del juego, inicio de partida y rotación de una pieza. Se corrigió un error al abrir la ruta del tablero: el proveedor de servicios del juego ahora queda por encima del navegador principal.
- `flutter test`: no ejecutado en este avance.
- En Android, los flujos se recorrieron manualmente con el emulador y `adb`. Para capturar iOS se usó una prueba temporal y dependencias SDK, retiradas después; respuesta y caché web quedaron verificadas. Face ID exitoso/cancelado requiere validación en iPhone real.
- iOS: `flutter drive` temporal ejecutado en iPhone 17 Simulator (iOS 27.2 / Xcode 27.2); capturas revisadas y guardadas.
- Se usó asistencia de IA para integrar la fuente de la Práctica 4, añadir la pantalla de sensores y preparar configuración/documentación. El estudiante debe revisar el código, ejecutar las pruebas pendientes y reportar cualquier error encontrado.

## Plataformas

- Android: `minSdk 24`; no se solicitan permisos de almacenamiento global. Los documentos externos se eligen con el selector del sistema.
- iOS: despliegue mínimo 15.0. Build y recorrido básico verificados en iPhone 17 Simulator (iOS 27.2 / Xcode 27.2).
- Bluetooth todavía no está habilitado; por ello el manifiesto no pide permisos Bluetooth ni ubicación innecesarios.

## Desarrollo

```bash
flutter pub get
flutter analyze
flutter test
```

Flutter 3.47.9 / Dart 3.13.7. Dependencias directas adicionales a Flutter SDK: `file_picker 13.3.2`, `sensors_plus 7.1.1`, `local_auth 3.0.2`, `audioplayers 6.8.1`, `path_provider 2.1.6`, `share_plus 13.3.1`, `shared_preferences 2.5.6`, `xml 7.1.0`, `image 4.12.0`, `mime 2.1.0`, `open_filex 5.0.0`, `intl 0.20.3`, `path 1.9.1`. `pubspec.lock` es la referencia completa reproducible.

## English

Flutter app for Android 24+ and iOS 15+, combining the Practice 4 file manager and Circuito Guinda game with accelerometer and gyroscope readings reported by the operating system. For a clean Android checkout, install Flutter 3.47.9, Android Studio/SDK, and an AVD named `Pixel_4a`, then run `./scripts/run_pixel4a.sh`. Dependencies are locked in `pubspec.lock`; machine-specific SDK paths and signing keys are not committed.

The app was built and exercised in an iPhone 17 simulator (iOS 27.2 / Xcode 27.2), including the simulated web response and cache flows. File deletion uses system authentication, verified with the Android emulator's virtual fingerprint; iOS Face ID remains to be validated on a real iPhone. The web view is an offline fixture simulation; BLE multiplayer, file transfer, and a real Bluetooth-relayed HTTPS client remain unimplemented. See [`README for IAS/README.md`](README%20for%20IAS/README.md) for architecture, protocol proposal, limitations, and the verification matrix.

## Uso de IA

Se usó asistencia de IA para integrar código de la Práctica 4, añadir/ajustar sensores, proteger el borrado con `local_auth`, preparar la vista web simulada y actualizar documentación. Se corrigió el ámbito de servicios para que las rutas del juego local funcionen. Verificado con `flutter analyze`, APK Android, huella virtual del AVD y consulta/caché de ejemplo; la prueba temporal iOS y sus dependencias ya se habían retirado. Las pruebas automatizadas permanentes y el relay BLE real siguen pendientes.
