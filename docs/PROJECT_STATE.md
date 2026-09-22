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
- Versión Android activa en prueba cerrada Alpha: `1.0.0 (16)`.
- Lista configurada: 20 verificadores.
- Canal de comentarios: `support@urbantrack.io`.
- Para la ficha iOS, Yely confirmó el 21/09/2026 un teléfono de contacto para App Review, que la app no muestra contenido de terceros que requiera licencias adicionales y que la distribución en la UE se realiza como actividad comercial. El contacto de App Review y los derechos de contenido ya se registraron; la verificación DSA sigue pendiente.
- Para la solicitud de acceso a producción de Google Play, Yely confirmó el 22/09/2026 que invitó a conocidos de la empresa, amigos, la diseñadora y contactos de tecnología y comercio. Consideró difícil conseguir que instalaran y usaran la app porque esperaban descargarla directamente desde la tienda. Confirmó que los comentarios recibidos están en el documento compartido de testers.

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
- Corrección local del 21/09/2026 para notas de clientes y obras: límite visible de 2.000 caracteres al escribir o pegar, con validación adicional antes del repositorio. En notas de obra, un fallo al guardar ya conserva el texto dentro del formulario y permite reintentar con el mismo identificador de solicitud; el botón de recarga del historial solo se muestra ante errores de lectura. La suite Flutter aprobó 150 pruebas y `dart analyze lib test` no reportó observaciones. La corrección aún no se ha distribuido a los testers.
- El 22/09/2026 se preparó `docs/google-play-production-access-draft.md` con respuestas basadas en el feedback y campos pendientes de confirmación de Yely; no se envió la solicitud. CI generó y verificó un AAB firmado de validación `1.0.0 (17)` desde la rama `codex/android-notes-ci-validation` (run `35754448098`). El AAB aún no se cargó en Google Play ni se probó en dispositivo.

# Pending Work

- La cuenta titular ya puede abrir el formulario de solicitud de acceso a producción (captura de Yely del 22/09/2026); preparar respuestas veraces sobre reclutamiento, participación, feedback y preparación antes de enviarlo. No asumir que la app ya está aprobada o publicada.
- Validar en los dispositivos Android reportados que Google Play use el correo invitado y que el usuario siga adherido mediante el vínculo web de la prueba; la consola confirma que Alpha está activo con `16 (1.0.0)`, 20 correos seleccionados y cobertura en 177 países o regiones.
- Cargar las dos capturas iPhone provistas por la cliente en el gestor multimedia de App Store Connect.
- Completar la verificación DSA del comerciante: Apple requiere dirección postal, teléfono y correo para mostrar públicamente en la ficha de la UE, sujetos a verificación. Solicitar a Yely los datos comerciales específicos que autoriza publicar; no asumir que la dirección de su cuenta sea la correcta.
- La captura recibida confirma que la nota problemática era de obra y muestra «Ocurrió un error al agregar la nota» con un botón «Reintentar». Confirmar con la tester la longitud aproximada y si la nota apareció tras reiniciar o quedó una operación pendiente en Sincronización. No eliminar ni truncar operaciones pendientes sin preservar el texto original. Validar el nuevo flujo en Android antes de distribuirlo.
- Confirmar si se usó algún proveedor de pruebas pagado, la participación no documentada en el feedback y la estimación de instalaciones del primer año; revisar las respuestas del borrador antes de completar el formulario de acceso a producción.
- Añadir la versión iOS 1.0 a revisión y enviarla a App Review una vez completados y verificados los requisitos pendientes.
- Preparar y enviar la solicitud de acceso a producción cuando la opción quede habilitada, respondiendo con evidencia real de la prueba; el envío no publica automáticamente la app.
- Completar la verificación de desarrolladores de Android antes del 30/09/2026.

# Required Access

- Google Play Console: administración de la app y seguimiento de la prueba; disponible.
- App Store Connect: distribución iOS; disponible.

# Blockers

- El 22/09/2026 Google Play Console muestra cumplidos los 14 días y 12 verificadores. En nuestra sesión el botón de solicitud continúa deshabilitado y no tenemos acceso a «Usuarios y permisos»; en la cuenta titular de Yely sí se abrió el formulario. La causa exacta de la diferencia de acceso no está confirmada.
- La carga de capturas iOS desde Chrome requiere habilitar `Allow access to file URLs` para la extensión del navegador de Codex/ChatGPT; los dos archivos ya están descargados y validados localmente con dimensiones `1320 × 2868`.
- La sesión de App Store Connect se recuperó el 21/09/2026. La declaración DSA no se completó porque faltan los datos de contacto comercial público elegidos por la titular; el formulario quedó cancelado sin enviar.
- El build Android local de la corrección de notas volvió a fallar por `Unable to establish loopback connection` de Gradle en Windows; CI sí compiló y firmó el AAB `1.0.0 (17)`. Falta validación funcional en Android antes de distribuirlo.

# Relevant Risks

- Si el número de verificadores activos baja de 12, Google puede interrumpir o reiniciar el conteo continuo.
- No desinstalar la app Android como primer paso de diagnóstico si existen operaciones offline pendientes, porque podrían perderse datos locales aún no sincronizados.
- La verificación del desarrollador de Android tiene fecha límite del 30/09/2026.
- Apple aceptó el build iOS actual, pero advirtió que desde primavera de 2027 exigirá `MinimumOSVersion` 15.0 o superior; elevar ese mínimo deberá evaluarse en una versión futura por su impacto en dispositivos antiguos.
- La compilación Android local del 15/09/2026 no pudo iniciar Gradle por un rechazo de loopback del host; el riesgo quedó mitigado con un flujo de CI que generó y verificó correctamente el artefacto firmado.

# Change Requests / Additional Work

- Documento de feedback recibido: `UrbanTrack CRM - movil - testers`, con 14 observaciones.
- Correcciones clasificadas como incluidas: implementadas, validadas y empaquetadas en los builds Android/iOS `1.0.0 (16)`; distribución externa en proceso.
- Documento compartido de feedback actualizado el 15/09/2026: los puntos 1, 5, 6, 7, 10 y 13 quedaron resaltados en verde como atendidos dentro del hito; las ampliaciones fuera de alcance permanecen sin marcar.
- Observación mixta resuelta: el inicio de jornada sigue exigiendo GPS según el comportamiento acordado y el mensaje actual ya explica que debe activarse la ubicación. Permitir iniciar sin GPS continúa fuera del alcance.
- Propuestas clasificadas como mejoras o ampliaciones fuera del alcance actual: incluir el nombre de la obra en todos los mensajes/notificaciones; iniciar la jornada desde el detalle de una obra; añadir un control específico `+/-` o `Actualizar avance`; selección manual de ubicación en mapa; pin GPS ajustable; alta de obras offline; edición de obras offline; rediseño de la pantalla principal con contenido dinámico.
- Las mejoras fuera de alcance requieren definición, estimación y cotización separada antes de implementarse.
- Reporte del 21/09/2026: en Android, una tester pegó en una nota de obra un texto largo de Word, guardó, recibió «Ocurrió un error al agregar la nota» y el botón «Reintentar» no resolvió el problema; reinició la app. Se confirmó en código que ese botón solo recargaba la actividad, sin reenviar ni recuperar el texto de la nota fallida. La API pública no declara longitud máxima para notas. Se añadió protección local de 2.000 caracteres y se corrigió el flujo de error de notas de obra como correcciones preventivas del MVP; el supuesto cuelgue del backend y una posible operación previa encolada no se han reproducido ni resuelto.
