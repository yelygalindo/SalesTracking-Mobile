# Project Objective

Publicar UrbanTrackCRM para Android e iOS y validar el MVP de seguimiento comercial mediante pruebas controladas.

# Agreed Scope

- Aplicación móvil Flutter para gestionar clientes, obras, visitas, jornadas, notas, recordatorios, mapas, fotografías y sincronización sin conexión.
- Preparación de las fichas y procesos de distribución en App Store Connect y Google Play Console.

# Milestones

## Prueba cerrada de Google Play

- Entregable: versión Android disponible para verificadores autorizados.
- Estado: en curso.
- Criterio de aceptación de Google: al menos 12 verificadores inscritos durante 14 días consecutivos.
- Avance confirmado el 15/09/2026: 12 verificadores durante 8 días consecutivos.

## Acceso a producción de Google Play

- Entregable: solicitud de acceso a producción y posterior publicación pública.
- Estado: pendiente de completar la prueba cerrada.

# Out of Scope

- Nuevas funciones o cambios solicitados durante la prueba que no formen parte del alcance acordado, hasta revisar y clasificar cada solicitud.

# Confirmed Decisions

- Canal de prueba cerrada: Alpha.
- Versión Android activa en prueba cerrada Alpha: `1.0.0 (16)`.
- Lista configurada: 20 verificadores.
- Canal de comentarios: `support@urbantrack.io`.

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
- Build iOS firmado `1.0.0 (16)` generado, verificado, cargado y procesado correctamente en App Store Connect/TestFlight el 15/09/2026; asignado al grupo `Equipo interno` con 2 invitaciones y disponible para pruebas internas.

# Pending Work

- Completar los 6 días consecutivos restantes indicados por Google Play al 15/09/2026.
- Validar en los dispositivos Android reportados que Google Play use el correo invitado y que el usuario siga adherido mediante el vínculo web de la prueba; la consola confirma que Alpha está activo con `16 (1.0.0)`, 20 correos seleccionados y cobertura en 177 países o regiones.
- Confirmar que los testers internos instalen y validen la versión iOS `1.0.0 (16)` desde TestFlight.
- Solicitar acceso a producción cuando Google habilite la opción.
- Completar la verificación de desarrolladores de Android antes del 30/09/2026.

# Required Access

- Google Play Console: administración de la app y seguimiento de la prueba; disponible.
- App Store Connect: distribución iOS; disponible.

# Blockers

- El botón para solicitar acceso a producción permanece deshabilitado hasta completar 14 días consecutivos con al menos 12 verificadores.

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
