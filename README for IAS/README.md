# README for IAS · Arquitectura y estado

## Arquitectura actual

```text
Flutter UI
├── Gestor P4 (lib/core, lib/features/browser, viewer, library, settings)
├── Circuito Guinda P4 (lib/features/game/{core,game,saves,ui})
└── Sensores (lib/features/sensors)
    └── SensorInterval.normalInterval → sensors_plus → acelerómetro / giroscopio
```

La lógica del gestor usa servicios Dart y almacenamiento privado. El juego usa servicios y autosave JSON independientes, inyectados con `ServicesScope`. La página de sensores se suscribe al entrar y cancela streams en pausa o al salir; los errores del plugin se presentan como sensor no disponible. Android e iOS usan `sensors_plus`; el AVD puede reportar valores simulados.

## Decisiones y reutilización

- Se reutilizó el gestor y Circuito Guinda de `p4_flutter_backup` (fuente original local de la Práctica 4): navegación, servicios, persistencia, visores y juego. En este repo quedan integrados bajo `lib/`.
- Flutter y Dart se fijan como versión de trabajo en el README; `pubspec.lock` fija las versiones exactas de paquetes. No se incluye `local.properties`, artefactos de build ni claves de firma.
- Se eligió Flutter, con UI compartida y adaptadores de sensores por `sensors_plus`. Min Android API 24. iOS requiere validar Xcode en macOS; no se afirma esa validación.
- El AVD esperado se llama `Pixel_4a`. El script `scripts/run_pixel4a.sh` genera la configuración local Flutter/Gradle, restaura deps y arranca el emulador.

## Contrato propuesto para el canal BLE (pendiente)

No hay aún servicio BLE implementado. El contrato propuesto para orientar las siguientes tareas es un servicio GATT propio con una característica RX (write/write without response cuando se negocie) y otra TX (notify/indicate), con cliente y servidor adaptables a central/periférico en ambos sistemas. No se debe asumir que iOS permite los mismos roles o anuncio de Android: validar interoperabilidad entre ambos sistemas cuando se implemente.

Cada mensaje será un frame UTF-8 JSON con campos obligatorios:

```json
{"v":1,"session":"uuid","seq":1,"type":"game.move","requestId":"uuid","payload":{}}
```

`v` versión, `session` partida/sesión, `seq` creciente por emisor, `type` tipo permitido, `requestId` idempotencia de solicitud y `payload` validado según tipo. Receptor rechaza versión/tipo/campos inválidos, sesión distinta, secuencias repetidas y transiciones fuera de turno. Fragmentación debe usar el máximo de payload negociado (`MTU - overhead`) e incluir id de mensaje, índice, total y ACK; nunca fijar un tamaño universal. Hash SHA-256 de archivo comprueba integridad, no identidad ni confidencialidad. La implementación debe declarar protección de enlace realmente ofrecida por SO/periférico.

## Estado frente a la práctica

| Requisito | Estado en este checkout |
|---|---|
| Gestor y juego P4 | Integrados; autosave local del juego |
| Acelerómetro y giroscopio | Lecturas reportadas por el sistema, valor/unidad/instante/estado e interacción básica. En simulador pueden ser virtuales o no estar disponibles. |
| Ausencia / pausa / reanudación sensores | Timeout/error informativo; streams se cancelan y se vuelven a abrir |
| Biometría al proteger acción de archivo | Borrado protegido por `local_auth`; huella virtual del AVD aceptada y credencial del dispositivo ofrecida como alternativa |
| Consulta web de demostración | Simulación local B→A con allowlist de dos rutas, estado/ID/tiempo, historial, favoritos y caché; no realiza HTTPS ni BLE |
| Juego sincronizado por Bluetooth, roles, secuencia/deduplicación | Pendiente; juego actual es local |
| Transferencia TXT/JSON/XML/JPG por Bluetooth, bloques, SHA-256 | Pendiente |
| Cliente HTTPS mediado por Bluetooth y controles anti SSRF | La pantalla demo valida esquema/dominio/ruta con fixtures locales; relay BLE y peticiones HTTPS reales pendientes |
| Android Pixel 4a | `flutter run` compiló, instaló y abrió en AVD `Pixel_4a`; gestor, visor, ajustes, sensores y juego local recorridos. Capturas en `evidencias/`. |
| BLE entre Android e iOS | Pendiente de implementar el transporte y validar interoperabilidad |
| iOS/Xcode | Xcode 27.2 e iPhone 17 Simulator (iOS 27.2): app compilada y pantallas recorridas; capturas incluidas |

## Matriz de pruebas y evidencias

Completar `obtenido`, `dispositivo/versión` y evidencia solo tras ejecutar cada caso. Las capturas del AVD y simulador iOS están en `evidencias/`; los sensores del AVD pueden ser virtuales o no reportar datos.

| Caso | Pasos | Esperado | Obtenido / dispositivo / evidencia |
|---|---|---|---|
| Acelerómetro/giroscopio disponibles | Abrir Sensores, observar valores | Valor, unidad, instante y estado; distinguir simulación | AVD Pixel_4a reportó valores; evidencia en `evidencias/05_sensores.png` |
| Sensor ausente | Abrir Sensores en simulador iOS | Mensaje informativo, app estable | iPhone 17 Simulator: sin lecturas, aviso verificado |
| Pausa/reanudación | Ir a segundo plano y volver | Streams detenidos y retomados | Pendiente |
| Permiso denegado | Aplicable al permiso que se implemente | Explicación y salida segura | Pendiente (sensores no piden permiso móvil) |
| Juego local | Abrir Juego, Modo Clásico y girar pieza | Tablero y contador de movimiento | AVD Pixel_4a: abierto y un giro aplicado; no es sesión Bluetooth |
| Juego BLE, turno y duplicado | Requiere implementación BLE | Una jugada por secuencia | Pendiente |
| TXT/JSON/XML/JPG, bloque grande | Requiere implementación BLE | Archivo verificado antes de publicar | Pendiente |
| Hash incorrecto / cancelar / desconectar | Requiere implementación BLE | Temporal descartado; historial fallido/cancelado | Pendiente |
| Web simulada con A disponible/sin conexión | Consultar recurso de ejemplo; desconectar A y repetir | Mostrar respuesta nueva o caché identificada | AVD Pixel_4a: respuesta local 200 y copia de caché; capturas `evidencias/16_consulta_web_respuesta.png` y `17_consulta_web_cache.png` |
| Web real con B sin Internet | Requiere proxy HTTPS por BLE en A | Sólo A accede a red; respuesta y caché etiquetadas | Pendiente de implementar el relay BLE real |
| Borrado con biometría | Eliminar un archivo y autenticar | Diálogo del sistema; no borrar si se cancela | AVD Android 17: huella virtual aceptada; confirmación/resultado en `evidencias/18_biometria_confirmacion.png` y `19_biometria_autorizada.png` |

## Limitaciones y riesgos conocidos

Este incremento ya protege el borrado con biometría del sistema y contiene una simulación local del visor web. Aún faltan los transportes BLE del juego, transferencia y relay HTTPS real; la simulación web no realiza llamadas de red. No hay pruebas de interoperabilidad ni video. Antes de entregar: implementar BLE Android/iOS, validar allowlist/redirecciones/tamaño/timeout del intermediario HTTPS, completar pruebas unitarias de lógica/protocolo y documentar rechazo/revocación.

## Registro de asistencia de IA

Asistencia de IA para integrar la fuente existente de P4, ajustar sensores, añadir autenticación del sistema al borrar y construir la vista web simulada. Se corrigió el ámbito de servicios del juego y se añadió un timeout de sensores. Validación: `flutter analyze`, APK debug, huella virtual en AVD Android, respuesta JSON local y caché sin conexión; prueba iOS temporal previa retirada. La interoperabilidad BLE y el relay HTTPS real siguen pendientes.
