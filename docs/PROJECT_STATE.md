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
- Avance confirmado el 10/09/2026: 12 verificadores durante 3 días consecutivos.

## Acceso a producción de Google Play

- Entregable: solicitud de acceso a producción y posterior publicación pública.
- Estado: pendiente de completar la prueba cerrada.

# Out of Scope

- Nuevas funciones o cambios solicitados durante la prueba que no formen parte del alcance acordado, hasta revisar y clasificar cada solicitud.

# Confirmed Decisions

- Canal de prueba cerrada: Alpha.
- Versión Android en prueba: `1.0.0 (13)`.
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

# Pending Work

- Completar los 11 días consecutivos restantes indicados por Google Play al 10/09/2026.
- Generar y distribuir un nuevo build con las correcciones incluidas para validación de los testers.
- Solicitar acceso a producción cuando Google habilite la opción.
- Completar la verificación de desarrolladores de Android antes del 30/09/2026.

# Required Access

- Google Play Console: administración de la app y seguimiento de la prueba; disponible.
- App Store Connect: distribución iOS; disponible durante el proceso de publicación.

# Blockers

- El botón para solicitar acceso a producción permanece deshabilitado hasta completar 14 días consecutivos con al menos 12 verificadores.

# Relevant Risks

- Si el número de verificadores activos baja de 12, Google puede interrumpir o reiniciar el conteo continuo.
- La verificación del desarrollador de Android tiene fecha límite del 30/09/2026.
- La compilación Android local del 15/09/2026 no pudo iniciar Gradle porque el host rechazó su conexión interna de loopback (`java.io.IOException: Unable to establish loopback connection`); el código sí superó análisis y pruebas, pero el siguiente artefacto debe generarse mediante CI o un host de compilación compatible.

# Change Requests / Additional Work

- Documento de feedback recibido: `UrbanTrack CRM - movil - testers`, con 14 observaciones.
- Correcciones clasificadas como incluidas: implementadas y validadas localmente; pendientes de distribución en un nuevo build.
- Observación mixta resuelta: el inicio de jornada sigue exigiendo GPS según el comportamiento acordado y el mensaje actual ya explica que debe activarse la ubicación. Permitir iniciar sin GPS continúa fuera del alcance.
- Propuestas clasificadas como mejoras o ampliaciones fuera del alcance actual: incluir el nombre de la obra en todos los mensajes/notificaciones; iniciar la jornada desde el detalle de una obra; añadir un control específico `+/-` o `Actualizar avance`; selección manual de ubicación en mapa; pin GPS ajustable; alta de obras offline; edición de obras offline; rediseño de la pantalla principal con contenido dinámico.
- Las mejoras fuera de alcance requieren definición, estimación y cotización separada antes de implementarse.
