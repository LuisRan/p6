# README for IAS · Arquitectura y estado

## Arquitectura actual

```text
Flutter UI
├── Gestor P4 (lib/core, lib/features/browser, viewer, library, settings)
├── Circuito Guinda P4 (lib/features/game/{core,game,saves,ui})
└── Sensores (lib/features/sensors)
    └── SensorInterval.normalInterval → sensors_plus → acelerómetro / giroscopio
```

La lógica del gestor usa servicios Dart y almacenamiento privado. El juego usa servicios y autosave JSON independientes, inyectados con `ServicesScope`. La página de sensores se suscribe al entrar y cancela streams en pausa o al salir; los errores del plugin se presentan como sensor no disponible. Android e iOS usan `sensors_plus`; se debe confirmar el hardware real antes de afirmar disponibilidad.

## Decisiones y reutilización

- Se reutilizó el gestor y Circuito Guinda de `p4_flutter_backup` (fuente original local de la Práctica 4): navegación, servicios, persistencia, visores y juego. En este repo quedan integrados bajo `lib/`.
- Flutter y Dart se fijan como versión de trabajo en el README; `pubspec.lock` fija las versiones exactas de paquetes. No se incluye `local.properties`, artefactos de build ni claves de firma.
- Se eligió Flutter, con UI compartida y adaptadores de sensores por `sensors_plus`. Min Android API 24. iOS requiere validar Xcode en macOS; no se afirma esa validación.
- El AVD esperado se llama `Pixel_4a`. El script `scripts/run_pixel4a.sh` genera la configuración local Flutter/Gradle, restaura deps y arranca el emulador.

## Contrato propuesto para el canal BLE (pendiente)

No hay aún servicio BLE implementado. El contrato propuesto para orientar las siguientes tareas es un servicio GATT propio con una característica RX (write/write without response cuando se negocie) y otra TX (notify/indicate), con cliente y servidor adaptables a central/periférico en ambos sistemas. No se debe asumir que iOS permite los mismos roles o anuncio de Android: validar en dos equipos físicos antes de cerrar el diseño.

Cada mensaje será un frame UTF-8 JSON con campos obligatorios:

```json
{"v":1,"session":"uuid","seq":1,"type":"game.move","requestId":"uuid","payload":{}}
```

`v` versión, `session` partida/sesión, `seq` creciente por emisor, `type` tipo permitido, `requestId` idempotencia de solicitud y `payload` validado según tipo. Receptor rechaza versión/tipo/campos inválidos, sesión distinta, secuencias repetidas y transiciones fuera de turno. Fragmentación debe usar el máximo de payload negociado (`MTU - overhead`) e incluir id de mensaje, índice, total y ACK; nunca fijar un tamaño universal. Hash SHA-256 de archivo comprueba integridad, no identidad ni confidencialidad. La implementación debe declarar protección de enlace realmente ofrecida por SO/periférico.

## Estado frente a la práctica

| Requisito | Estado en este checkout |
|---|---|
| Gestor y juego P4 | Integrados; autosave local del juego |
| Acelerómetro y giroscopio | Lecturas reportadas por el sistema, valor/unidad/instante/estado e interacción básica. En emulador pueden ser simuladas. |
| Ausencia / pausa / reanudación sensores | Error mostrado; streams se cancelan y se vuelven a abrir |
| Biometría al proteger acción de archivo | Pendiente |
| Juego sincronizado por Bluetooth, roles, secuencia/deduplicación | Pendiente; juego actual es local |
| Transferencia TXT/JSON/XML/JPG por Bluetooth, bloques, SHA-256 | Pendiente |
| Cliente HTTPS mediado por Bluetooth y controles anti SSRF | Pendiente |
| Android Pixel 4a | `flutter run` compiló, instaló y abrió en AVD `Pixel_4a`; gestor, visor, ajustes, sensores y juego local recorridos. Capturas en `evidencias/`. Físico pendiente. |
| Dos teléfonos físicos / pares Android-iOS | Pendiente de pruebas y evidencia |
| iOS/Xcode | No ejecutable en este entorno: Xcode no está seleccionado y `simctl` no está disponible |

## Matriz de pruebas y evidencias

Completar `obtenido`, `dispositivo/versión` y evidencia física solo tras ejecutar cada caso. Las capturas del AVD están en `evidencias/`; sus lecturas de sensores pueden ser virtuales.

| Caso | Pasos | Esperado | Obtenido / dispositivo / evidencia |
|---|---|---|---|
| Acelerómetro/giroscopio disponibles | Abrir Sensores, observar valores | Valor, unidad, instante y estado; distinguir simulación | AVD Pixel_4a reportó valores; teléfono físico pendiente |
| Sensor ausente | Desactivar/simular ausencia | Mensaje informativo, app estable | Pendiente |
| Pausa/reanudación | Ir a segundo plano y volver | Streams detenidos y retomados | Pendiente |
| Permiso denegado | Aplicable al permiso que se implemente | Explicación y salida segura | Pendiente (sensores no piden permiso móvil) |
| Juego local | Abrir Juego, Modo Clásico y girar pieza | Tablero y contador de movimiento | AVD Pixel_4a: abierto y un giro aplicado; no es sesión Bluetooth |
| Juego BLE, turno y duplicado | Requiere implementación BLE | Una jugada por secuencia | Pendiente |
| TXT/JSON/XML/JPG, bloque grande | Requiere implementación BLE | Archivo verificado antes de publicar | Pendiente |
| Hash incorrecto / cancelar / desconectar | Requiere implementación BLE | Temporal descartado; historial fallido/cancelado | Pendiente |
| Web con B sin Internet | Requiere proxy BLE en A | Respuesta nueva solo si A tiene Internet; caché etiquetada | Pendiente |

## Limitaciones y riesgos conocidos

Este incremento no cubre todavía los tres ejercicios nuevos que necesitan Bluetooth ni biometría. No hay pruebas de interoperabilidad ni video, y el AVD no representa sensores de hardware real. Antes de entregar: implementar los adaptadores BLE Android/iOS, validar lista permitida/redirects/tamaño/timeout del intermediario HTTPS, completar pruebas unitarias de lógica y de protocolo, documentar rechazo/revocación y terminar matriz con capturas o video auténticos. Usar PR por propósito, checks CI y revisiones ajenas según las reglas del curso.

## Registro de asistencia de IA

Asistencia de IA para integrar la fuente existente de P4, añadir la UI de sensores y preparar configuración/documentación. También se corrigió el ámbito de servicios del juego para que las rutas de partida reciban el proveedor usado por el menú. Validación: `flutter analyze` sin incidencias; `flutter build apk --debug` exitoso; app abierta; gestor, JSON, imagen, ajustes, sensores y juego local recorridos. No se ejecutaron pruebas automatizadas ni se verificó teléfono físico/iOS. No se añadieron pruebas temporales ni dependencias temporales. Revisar el código y completar verificaciones restantes antes de la entrega.
