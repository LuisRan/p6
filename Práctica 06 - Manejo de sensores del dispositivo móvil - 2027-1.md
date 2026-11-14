**Instituto Politécnico Nacional** 

**Escuela Superior de Cómputo** 

| Programa académico / Plan de estudios |
| :---: |
| Ingeniería en Sistemas Computacionales / 2020 |

| Unidad de aprendizaje |
| :---: |
| Desarrollo de aplicaciones móviles nativas |

**Práctica 6: Manejo de sensores del dispositivo móvil** 

Semestre 2027-1 · Grupo 7CV4 · Fecha de entrega: jueves 19 de noviembre de 2026\. 

Objetivo: ampliar el gestor de archivos y el juego de prácticas anteriores con sensores y  comunicación entre dispositivos. Implementar transferencia de archivos, juego sincronizado y un  cliente de consulta web cuyo acceso remoto pase por otro dispositivo mediante Bluetooth. 

**Alcance y tecnología** 

• Elegir KMP con Kotlin y UI compartida o nativa, o Flutter con Dart. Separar lógica común de  adaptadores por plataforma y documentar bibliotecas y versiones. Android Views/XML se  conserva como referencia del programa; Compose está permitido. 

• Objetivos móviles del curso: Android API 24+ e iOS 15+, sujetos a los mínimos de las  dependencias elegidas. Demostrar las funciones equivalentes en ambos sistemas y registrar las  diferencias reales de hardware. La compilación y ejecución de iOS requieren macOS y Xcode; no  se exige comprar una Mac, pero sí planificar acceso local, compartido o remoto y documentar lo  que se pudo verificar. 

• Aplicar Tema Guinda IPN y Tema Azul ESCOM, adaptación claro/oscuro y controles accesibles.  Solicitar permisos al necesitar una función y resolver cancelación, rechazo, revocación y recurso  no disponible sin cierres inesperados. 

**Ejercicio 1 Sensores e interacción** 

• Integrar al menos dos sensores disponibles, preferentemente acelerómetro y giroscopio. Mostrar  valor, unidad, instante y estado; usar sus lecturas en una acción del gestor o del juego. Los valores  simulados sirven para pruebas automatizadas, pero se distinguen de lecturas físicas. 

• Detectar sensores ausentes, elegir frecuencia razonable y detener suscripciones cuando no se  usan. Separar el sensor tras una interfaz para probar valores normales, extremos y ausencia de  datos. Registrar el comportamiento al pausar y reanudar la app. 

• En el gestor, proteger una acción sensible con autenticación biométrica del sistema y alternativa  cuando corresponda. La biometría no entrega la huella a la app ni cifra archivos por sí sola; no  cuenta como uno de los dos sensores de movimiento.  
**Juego por Bluetooth** 

• Ampliar el juego de la Práctica 4 con una sesión entre dos dispositivos. Definir quién inicia, quién  acepta y cómo se eligen roles; mostrar conexión, turno, resultado y errores en ambos extremos. 

• Definir mensajes con versión de protocolo, identificador de partida, número de secuencia y tipo.  Validar movimiento y turno; impedir que un mensaje duplicado repita una jugada. Probar  desconexión, intento de reconexión y salida de un participante sin corromper la partida. 

• Persistir el estado necesario para recuperar la sesión o informar que terminó. No depender de  Firebase, Wi-Fi o Internet para demostrar la partida por Bluetooth. 

**Compatibilidad del transporte** 

• Para interoperar Android e iOS, usar un protocolo BLE con servicios y características  documentados y comprobar los roles central/periférico en el hardware elegido. Fragmentar  mensajes según las capacidades negociadas; no fijar un tamaño universal de paquete. 

• Bluetooth Classic con sockets Android puede mostrarse como variante Android–Android. No se  acepta suponer que ese mismo código RFCOMM funciona sin adaptación en iOS. La matriz debe  separar transportes, sistemas, roles y pares realmente probados. 

• Demostrar con dos dispositivos físicos compatibles al menos una sesión real. Probar ambos  clientes móviles y declarar expresamente los pares aún no verificados. Acordar con el docente el  acceso compartido al hardware antes de la entrega. 

Referencia de arquitectura: BattleNaval\_V2 puede servir para estudiar conexión y sincronización.  Registrar qué ideas o código se reutilizó y comprobar su compatibilidad; no sustituye la  implementación ni las pruebas propias.  
**Ejercicio 2 Transferencia de archivos** 

• Extender el gestor de la Práctica 4 para enviar y recibir TXT, JSON, XML y JPG mediante  Bluetooth. Seleccionar únicamente documentos propios o autorizados por el sistema; confirmar  dispositivo y archivo antes del envío. 

• Implementar descubrimiento, solicitud de conexión y aceptación explícita del receptor.  Intercambiar metadatos: identificador, nombre lógico, tipo, longitud y suma SHA-256. Validar  tamaño y nombre; nunca usar una ruta recibida como destino arbitrario. 

• Enviar datos por bloques con secuencia y confirmación. Mostrar progreso, cancelar, detectar  pérdida de conexión y evitar registrar como completa una transferencia parcial. No es obligatorio  reanudar desde el último bloque, pero sí explicar y probar la política elegida. 

• Guardar primero en un archivo temporal privado; comprobar longitud e integridad antes de  confirmar el archivo final. La suma detecta alteraciones, pero no autentica al emisor ni sustituye  cifrado. Documentar la protección real de la sesión y no inventar criptografía propia. 

• Mantener historial de enviados y recibidos, una cola acotada y estados de pendiente, en curso,  completado, cancelado y fallido. Confirmar que reiniciar no convierte una transferencia fallida en  exitosa. 

• Probar archivos pequeños de los cuatro formatos y un archivo mayor que requiera varios bloques.  Definir y comunicar un límite de tamaño didáctico, sin prometer el rendimiento de una transferencia  Wi-Fi. 

**Permisos y ciclo de vida** 

• Android: justificar permisos de búsqueda, conexión y anuncio según versión y rol. iOS: declarar la  finalidad de Bluetooth y respetar sus restricciones. No solicitar ubicación o ejecución permanente  si la función elegida no las necesita. 

• El núcleo se demuestra en primer plano. Si se añade trabajo en segundo plano, justificar la API y  límites del sistema. Los avisos de conexión o transferencia son locales; no son notificaciones push  de FCM.  
**Ejercicio 3 Consulta web a través de Bluetooth** 

Construir un visor de consulta controlado. El dispositivo A tiene Internet y realiza peticiones HTTPS;  el dispositivo B tiene Bluetooth activo y no dispone de Wi-Fi ni datos celulares. B solicita el recurso  a A y presenta la respuesta recibida por Bluetooth. 

• Mostrar roles cliente/servidor, dirección solicitada, estado, tiempo y errores. Incluir atrás/adelante  sobre el historial local, favoritos y caché identificada con fecha. No se exige un navegador general  ni compartir la conexión de todo el sistema operativo. 

• Usar un conjunto documentado de recursos HTTPS de prueba. Validar esquema, dominio y  redirecciones; impedir acceso a destinos locales, privados o no autorizados desde el  intermediario. Acotar tamaño, duración y número de solicitudes. 

• Transmitir texto o JSON y, como ampliación, imágenes pequeñas. Renderizar contenido seguro y  explicar los formatos admitidos. No pedir credenciales de sitios de terceros ni prometer inicio de  sesión universal, ejecución de scripts o navegación completa por cualquier sitio. 

• Añadir identificador de petición, estado de respuesta y control de duplicados al protocolo.  Distinguir respuesta de caché y respuesta de red. Probar servidor sin Internet, timeout, rechazo  de destino y pérdida de Bluetooth. 

• Grabar ambos dispositivos en una toma continua: demostrar que B no tiene conectividad directa  y que una consulta nueva sólo funciona cuando A está conectado. Al apagar Bluetooth, B debe  mostrar el fallo o una copia de caché claramente identificada. 

Se permiten KMP, Compose Multiplatform y Flutter. Un ejemplo Views/XML puede acompañar la  explicación de Android, pero no se impone como única interfaz.  
**Pruebas y evidencias específicas** 

Matriz mínima: sensor disponible/ausente, pausa/reanudación, permiso denegado, sesión de juego,  mensaje duplicado, cuatro formatos de archivo, integridad fallida, cancelación, desconexión y  consulta web con B sin Internet. Registrar plataforma, versión, dispositivo, pasos, esperado, obtenido  y evidencia real. 

Conservar diagrama de arquitectura, contrato del protocolo, pruebas automatizadas de lógica y  mensajes, guía para reproducir los pares probados y video de la comunicación. Entregar APK de  prueba y evidencia de ejecución iOS; no publicar claves de firma. No se exige subir esta práctica a  una tienda. 

**Entrega y proceso del semestre** 

• Entregar el código y la documentación en un repositorio público de GitHub. Classroom recibe la  liga. El README.md y los archivos Markdown sustituyen el informe Word/PDF del estudiante;  incrustar allí las capturas completas y legibles, con un recuadro sobre lo relevante cuando haga  falta. 

• Trabajar en ramas por propósito. Cada entrega entra por un PR con título y descripción en inglés:  problema, cambio, forma de prueba y evidencia visual. Vincular el issue, atender la revisión de  otra persona y conservar los checks de CI en verde antes de integrar. El autor no aprueba su  propio PR. 

• Usar GitHub Projects para el backlog: historias, criterios de aceptación, prioridad, estimación  relativa, estado e iteración. Registrar Objetivo del Sprint, trabajo seleccionado, revisión del  incremento y una mejora de retrospectiva. Los puntos no son horas ni calificación individual. 

• Mantener README en español e inglés, instrucciones reproducibles, matriz de pruebas y carpeta  README for IAS con arquitectura, decisiones, estado y limitaciones. Actualizar la documentación  junto con el cambio que la afecta. Declarar herramientas de IA, tareas asistidas y cómo se verificó  el resultado, incluidos errores detectados. 

• Todos deben ayudar en los proyectos Salones y POW. El docente coordina issues y alcances;  cada estudiante identifica sus contribuciones y revisiones en ambos repositorios. Se respeta la  tecnología existente y no se convierte un proyecto completo a otro framework. Estos aportes  forman parte del proyecto del semestre y se distinguen de las funciones de esta práctica. 

• La autoría y la defensa son individuales, incluso si se usa un repositorio del equipo o se comparte  hardware. Identificar commits, PR, revisiones y resultados propios. El mínimo de tres PR y tres  revisiones por estudiante del curso se acumula durante el semestre; no se exige repetirlo por cada  práctica. 

• La evaluación comprueba funcionalidad, explicación del código, pruebas y proceso verificable. Un  PR ausente o CI fallida no constituye entrega completa. 

Fecha de entrega: jueves 12 de noviembre de 2026\. 

**Referencias de apoyo** 

Android Bluetooth: https\://developer.android.com/develop/connectivity/bluetooth/bt-permissions Apple Core Bluetooth: https\://developer.apple.com/documentation/corebluetooth