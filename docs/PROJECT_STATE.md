# Project Objective

Publicar UrbanTrackCRM para Android e iOS y validar el MVP de seguimiento comercial mediante pruebas controladas.

# Agreed Scope

- Aplicación móvil Flutter para gestionar clientes, obras, visitas, jornadas, notas, recordatorios, mapas, fotografías y sincronización sin conexión.
- Preparación de las fichas y procesos de distribución en App Store Connect y Google Play Console.

# Milestones

## Prueba cerrada de Google Play

- Entregable: versión Android disponible para verificadores autorizados.
- Estado: criterio de duración cumplido según Google Play Console el 22/09/2026; la prueba cerrada sigue disponible.
- Criterio de aceptación de Google: al menos 12 verificadores inscritos durante 14 días consecutivos.
- El 22/09/2026 la consola marcó como completadas la versión de prueba cerrada, la inscripción de 12 verificadores y los 14 días mínimos con 12 verificadores.

## Acceso a producción de Google Play

- Entregable: solicitud de acceso a producción y posterior publicación pública.
- Estado: pendiente de solicitar; el botón «Solicitar acceso a producción» aún aparece deshabilitado en la sesión actual pese a que los tres requisitos figuran completos. Producción permanece inactiva.

# Out of Scope

- Nuevas funciones o cambios solicitados durante la prueba que no formen parte del alcance acordado, hasta revisar y clasificar cada solicitud.

# Confirmed Decisions

- Canal de prueba cerrada: Alpha.
- Versión Android publicada en prueba cerrada Alpha: `1.0.0 (16)`. La versión `1.0.0 (17)` se envió a revisión el 22/09/2026; aún no está disponible para testers.
- Lista configurada: 20 verificadores.
- Canal de comentarios: `support@urbantrack.io`.
- Para la ficha iOS, Yely confirmó el 21/09/2026 un teléfono de contacto para App Review, que la app no muestra contenido de terceros que requiera licencias adicionales y que la distribución en la UE se realiza como actividad comercial. El contacto de App Review y los derechos de contenido ya se registraron; la verificación DSA sigue pendiente.
- Para la solicitud de acceso a producción de Google Play, Yely confirmó el 22/09/2026 que invitó a conocidos de la empresa, amigos, la diseñadora y contactos de tecnología y comercio, sin contratar testers pagados. Consideró difícil conseguir que instalaran y usaran la app porque esperaban descargarla directamente desde la tienda. Confirmó que los comentarios recibidos están en el documento compartido de testers.

# Confirmed Requirements

- Mantener al menos 12 verificadores inscritos de forma continua durante 14 días.
- Cada verificador debe aceptar la invitación con el correo registrado.

# Completed Work

- Ficha de Google Play, recursos gráficos y declaraciones de contenido configurados.
- Prueba cerrada aprobada y activa en 177 países o regiones.
- Se alcanzó el mínimo de 12 verificadores.
- Correcciones incluidas del feedback implementadas y validadas el 15/09/2026: títulos técnicos del historial traducidos, refresco de avance de obra y estado del cliente al volver al listado, texto funcional de asignación de vendedor y validación completa del formato de correo. Evidencia local: 142 pruebas aprobadas y `dart analyze lib test` sin observaciones.
- Restricción de GPS al iniciar jornada revisada: es intencional y el mensaje existente ya indica cómo continuar cuando la ubicación está desactivada; no requirió cambios.
- Build Android firmado `1.0.0 (16)` generado y verificado mediante GitHub Actions el 15/09/2026; Google Play confirmó el envío 2 como `Publicado` en el canal cerrado Alpha el 15/09/2026 a las 13:21.
- Build iOS firmado `1.0.0 (16)` generado, verificado, cargado y procesado correctamente en App Store Connect/TestFlight el 15/09/2026; asignado al grupo `Equipo interno` con 2 invitaciones. La cliente confirmó el 18/09/2026 que instaló la actualización y validó las correcciones en iOS. El build 16 quedó seleccionado y guardado en la versión pública iOS 1.0 el 18/09/2026.
- Ficha pública iOS 1.0 completada el 18/09/2026 con texto promocional, descripción, palabras clave, URLs de soporte y marketing, copyright, categoría principal `Economía y empresa`, clasificación por edades 4+, datos disponibles para App Review y publicación automática tras la aprobación.
- Privacidad de iOS publicada el 18/09/2026: ocho tipos de datos declarados para funcionalidad de la app, vinculados a la identidad y sin uso para rastreo; política configurada en `https://urbantrack.io/privacy`.
- Precio iOS configurado como gratuito y disponibilidad confirmada para los 175 países o regiones. La distribución adicional en Mac con Apple silicon y Apple Vision Pro queda desactivada para mantener el lanzamiento en iOS/iPadOS probado.
- El 21/09/2026 se guardaron el acceso de prueba y contacto para App Review en la versión iOS 1.0; Apple habilitó `Añadir a revisión`. Se declaró que la app no contiene, muestra ni accede a contenido de terceros. No se añadió ni envió la versión a revisión.
- Corrección local del 21/09/2026 para notas de clientes y obras: límite visible de 2.000 caracteres al escribir o pegar, con validación adicional antes del repositorio. En notas de obra, un fallo al guardar ya conserva el texto dentro del formulario y permite reintentar con el mismo identificador de solicitud; el botón de recarga del historial solo se muestra ante errores de lectura. La suite Flutter aprobó 150 pruebas y `dart analyze lib test` no reportó observaciones. La corrección aún no está disponible para testers.
- El 22/09/2026 se preparó `docs/google-play-production-access-draft.md` con respuestas basadas en el feedback y campos pendientes de confirmación de Yely; no se envió la solicitud. CI generó y verificó un AAB firmado de validación `1.0.0 (17)` desde la rama `codex/android-notes-ci-validation` (run `35754448098`). `bundletool` generó una APK universal de prueba firmada con la clave debug local y se instaló temporalmente en el Galaxy S10 `SM-G973U`: el sistema confirmó `versionCode=17`, abrió la app e inició sesión con la cuenta de demostración. En una obra de demostración, el formulario limitó a 2.000 caracteres un ingreso de 2.200, guardó una nota de 2.000 y la mostró después de reiniciar la app; Sincronización indicó que no quedaban registros pendientes. La copia debug se desinstaló tras la prueba, sin operaciones pendientes. Las 9 pruebas de pantallas de clientes y obras volvieron a aprobar.
- El AAB `1.0.0 (17)` se cargó en Google Play Console para Alpha con notas en `es-419`. La vista previa no mostró pérdida de dispositivos compatibles frente al build 16. Se guardó un lanzamiento al 100 % de los verificadores de Alpha y se envió un único cambio a revisión; la consola confirmó «Se envió 1 cambio a revisión» y lo mostró en «Cambios en la etapa de revisión». Al cierre de esta actualización continuaban las verificaciones rápidas automáticas. No se modificó Producción ni se envió la solicitud de acceso a producción.

# Pending Work

- La cuenta titular ya puede abrir el formulario de solicitud de acceso a producción (captura de Yely del 22/09/2026); preparar respuestas veraces sobre reclutamiento, participación, feedback y preparación antes de enviarlo. No asumir que la app ya está aprobada o publicada.
- Esperar a que Google Play apruebe y publique `1.0.0 (17)` en Alpha; después verificar una actualización real desde Play con un correo invitado. Hasta entonces no indicar a los testers que la versión 17 ya está disponible.
- Validar en los dispositivos Android reportados que Google Play use el correo invitado y que el usuario siga adherido mediante el vínculo web de la prueba; la consola confirmó Alpha activo con `16 (1.0.0)`, 20 correos seleccionados y cobertura en 177 países o regiones antes del envío de la versión 17.
- Cargar las dos capturas iPhone provistas por la cliente en el gestor multimedia de App Store Connect.
- Completar la verificación DSA del comerciante: Apple requiere dirección postal, teléfono y correo para mostrar públicamente en la ficha de la UE, sujetos a verificación. Solicitar a Yely los datos comerciales específicos que autoriza publicar; no asumir que la dirección de su cuenta sea la correcta.
- La captura recibida confirma que la nota problemática era de obra y muestra «Ocurrió un error al agregar la nota» con un botón «Reintentar». Confirmar con la tester la longitud aproximada y si la nota apareció tras reiniciar o quedó una operación pendiente en Sincronización. No eliminar ni truncar operaciones pendientes sin preservar el texto original. El límite y guardado de 2.000 caracteres de la versión 17 se validaron en Android; el reintento específico ante un error de servidor solo tiene cobertura de prueba automatizada y no se reprodujo físicamente.
- La captura de Yely del 22/09/2026 muestra seleccionada «entre 0 y 10.000» instalaciones para el primer año; confirmar que fue una elección intencional. Revisar las respuestas del borrador, todas ajustadas al límite de 300 caracteres por campo, antes de completar el formulario de acceso a producción.
- Añadir la versión iOS 1.0 a revisión y enviarla a App Review una vez completados y verificados los requisitos pendientes.
- Preparar y enviar la solicitud de acceso a producción cuando la opción quede habilitada, respondiendo con evidencia real de la prueba; el envío no publica automáticamente la app.
- Verificación de desarrolladores de Android: Play Console mostró el 22/09/2026 «Todas tus apps se registraron correctamente para cumplir con los requisitos de verificación de desarrolladores de Android»; no queda acción pendiente para esta app según ese aviso.

# Required Access

- Google Play Console: administración de la app y seguimiento de la prueba; disponible.
- App Store Connect: distribución iOS; disponible.

# Blockers

- El 22/09/2026 Google Play Console muestra cumplidos los 14 días y 12 verificadores. En nuestra sesión el botón de solicitud continúa deshabilitado y no tenemos acceso a «Usuarios y permisos»; en la cuenta titular de Yely sí se abrió el formulario. La causa exacta de la diferencia de acceso no está confirmada.
- La carga de capturas iOS desde Chrome requiere habilitar `Allow access to file URLs` para la extensión del navegador de Codex/ChatGPT; los dos archivos ya están descargados y validados localmente con dimensiones `1320 × 2868`.
- La sesión de App Store Connect se recuperó el 21/09/2026. La declaración DSA no se completó porque faltan los datos de contacto comercial público elegidos por la titular; el formulario quedó cancelado sin enviar.
- El build Android local de la corrección de notas volvió a fallar por `Unable to establish loopback connection` de Gradle en Windows; CI sí compiló y firmó el AAB `1.0.0 (17)`. Un primer ingreso por ADB falló por interacción incorrecta con los campos; la cuenta de demostración se comprobó válida contra la API y luego inició sesión correctamente en el Galaxy S10. El límite y guardado de notas se validaron físicamente; la reproducción del error de servidor y del reintento real sigue sin probarse en el dispositivo.

# Relevant Risks

- Si el número de verificadores activos baja de 12, Google puede interrumpir o reiniciar el conteo continuo.
- No desinstalar la app Android como primer paso de diagnóstico si existen operaciones offline pendientes, porque podrían perderse datos locales aún no sincronizados.
- Google Play Console mostró completado el registro de todas las apps para la verificación de desarrolladores de Android el 22/09/2026; conservar evidencia si la consola vuelve a pedir una acción.
- Apple aceptó el build iOS actual, pero advirtió que desde primavera de 2027 exigirá `MinimumOSVersion` 15.0 o superior; elevar ese mínimo deberá evaluarse en una versión futura por su impacto en dispositivos antiguos.
- La compilación Android local del 15/09/2026 no pudo iniciar Gradle por un rechazo de loopback del host; el riesgo quedó mitigado con un flujo de CI que generó y verificó correctamente el artefacto firmado.
- La APK de validación usó firma debug local, distinta de la distribución de Google Play. Se retiró del Galaxy S10 al terminar la prueba, después de confirmar que no quedaban registros pendientes; la nota de prueba quedó en la obra de demostración del servidor.

# Change Requests / Additional Work

- Documento de feedback recibido: `UrbanTrack CRM - movil - testers`, con 14 observaciones.
- Correcciones clasificadas como incluidas: implementadas, validadas y empaquetadas en los builds Android/iOS `1.0.0 (16)`; distribución externa en proceso.
- Documento compartido de feedback actualizado el 15/09/2026: los puntos 1, 5, 6, 7, 10 y 13 quedaron resaltados en verde como atendidos dentro del hito; las ampliaciones fuera de alcance permanecen sin marcar.
- Observación mixta resuelta: el inicio de jornada sigue exigiendo GPS según el comportamiento acordado y el mensaje actual ya explica que debe activarse la ubicación. Permitir iniciar sin GPS continúa fuera del alcance.
- Propuestas clasificadas como mejoras o ampliaciones fuera del alcance actual: incluir el nombre de la obra en todos los mensajes/notificaciones; iniciar la jornada desde el detalle de una obra; añadir un control específico `+/-` o `Actualizar avance`; selección manual de ubicación en mapa; pin GPS ajustable; alta de obras offline; edición de obras offline; rediseño de la pantalla principal con contenido dinámico.
- Las mejoras fuera de alcance requieren definición, estimación y cotización separada antes de implementarse.
- Reporte del 21/09/2026: en Android, una tester pegó en una nota de obra un texto largo de Word, guardó, recibió «Ocurrió un error al agregar la nota» y el botón «Reintentar» no resolvió el problema; reinició la app. Se confirmó en código que ese botón solo recargaba la actividad, sin reenviar ni recuperar el texto de la nota fallida. La API pública no declara longitud máxima para notas. Se añadió protección local de 2.000 caracteres y se corrigió el flujo de error de notas de obra como correcciones preventivas del MVP; el supuesto cuelgue del backend y una posible operación previa encolada no se han reproducido ni resuelto.
