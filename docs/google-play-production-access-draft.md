# Google Play: solicitud de acceso a producción (borrador)

Estado: **no enviar todavía**. Google Play Console confirmó 12 verificadores durante 14 días y la cuenta titular puede abrir el formulario. Las respuestas deben reflejar únicamente hechos comprobados de la prueba cerrada; obtener aprobación de Yely antes de enviarlas. Solicitar acceso no publica la app.

Fuente del cuestionario: [Ayuda oficial de Google Play](https://support.google.com/googleplay/android-developer/answer/14151465). La redacción exacta de los campos puede variar en Play Console.

## 1. Acerca de la prueba cerrada

### ¿Cómo se reclutaron los verificadores? (máximo 300 caracteres en la captura)

Respuesta basada en lo confirmado por Yely (22/09/2026):

> Invitamos a conocidos de la empresa, amigos, la diseñadora y contactos de tecnología y comercio. Compartimos el enlace de la prueba cerrada y solicitamos que instalaran y usaran la app. No contratamos proveedores de testers.

Yely confirmó expresamente que no se usaron testers pagados. Texto: 224 de 300 caracteres.

### ¿Qué tan fácil fue reclutar verificadores?

Seleccionar **«Difícil»**. Yely indicó que fue complicado lograr que las personas instalaran y usaran la app, porque esperaban encontrarla directamente en la tienda.

### Participación y similitud con el uso esperado

Respuesta conservadora basada en el feedback documentado (277 de 300 caracteres):

> Según los comentarios, se usaron clientes, obras, jornadas, ubicación, notas y funciones sin conexión. No consta que cada persona probara todas las funciones. El uso se pareció al seguimiento comercial previsto; en producción esperamos una actividad más frecuente y prolongada.

### Comentarios recibidos y cómo se recopilaron

Respuesta para el campo de 300 caracteres (257 caracteres):

> Recibimos comentarios por mensajes y audios; la titular los reunió en un documento con 14 observaciones. Señalaron textos en inglés, listados sin refrescar, validación de correo, ubicación y uso sin conexión. Además reportaron un error al guardar una nota extensa.

Las correcciones efectivamente distribuidas y las propuestas fuera de alcance se detallan más abajo; el error de la nota extensa sigue pendiente de validación en dispositivo.

## 2. Acerca de la app

### Público objetivo

> Adultos que trabajan en equipos comerciales y realizan seguimiento de clientes, obras y visitas en campo. No está dirigida a menores.

### Valor para los usuarios

> UrbanTrackCRM permite consultar y actualizar clientes y obras, registrar visitas y jornadas con ubicación, gestionar notas y recordatorios y revisar el historial. Algunas operaciones pueden registrarse sin conexión y sincronizarse al restablecer Internet.

### Instalaciones estimadas durante el primer año

**Pendiente de Yely.** La estimación de negocio no se deduce de los 20 correos invitados a la prueba.

## 3. Preparación para producción

### Cambios realizados a partir de la prueba

> A partir del feedback, la versión 1.0.0 (16) corrigió textos visibles en el historial, la actualización de listados tras cambiar datos de clientes y obras, el texto de asignación de vendedor y la validación del formato de correo. El reporte posterior sobre una nota de obra muy larga motivó una protección adicional en el código; esta última corrección aún no se ha distribuido ni probado en un Android real.

### ¿Cómo se determinó que está lista para producción?

**No responder afirmativamente todavía.** La corrección del error de notas pasa 150 pruebas Flutter y `dart analyze lib test`, pero el build Android local está bloqueado por `Unable to establish loopback connection` de Gradle. Falta generar el build firmado en CI, distribuirlo en la pista cerrada, validar el guardado/reintento de notas en dispositivo y revisar los flujos críticos. No presentar una corrección local como entregada ni afirmar que el error del backend quedó resuelto.

## Decisiones y evidencia pendientes

1. Yely estima la franja de instalaciones del primer año que muestra el formulario.
2. El AAB Android `1.0.0 (17)` ya se generó y verificó en CI; falta probar la corrección de notas en un dispositivo antes de distribuirlo.
3. Antes de «Aplicar», ambas partes revisan las respuestas finales y la estabilidad de la versión candidata. Google revisa el acceso a producción por separado de la publicación pública.
