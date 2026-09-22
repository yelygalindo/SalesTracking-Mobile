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

Respuesta para el campo de 300 caracteres (264 caracteres):

> Recibimos comentarios por mensajes y audios; la titular los reunió en un documento con 14 observaciones. Señalaron textos en inglés, listados sin refrescar, validación de correo, ubicación y uso sin conexión. Además reportaron un error al guardar una nota extensa.

Las correcciones efectivamente distribuidas y las propuestas fuera de alcance se detallan más abajo; el error de la nota extensa sigue pendiente de validación en dispositivo.

## 2. Acerca de la app

### Público objetivo

Respuesta para el campo de 300 caracteres (227 caracteres):

> UrbanTrackCRM está dirigida a adultos de equipos comerciales que gestionan clientes, obras y visitas de campo para sus empresas. La usan vendedores y responsables de seguimiento comercial; no está diseñada para menores de edad.

### Valor para los usuarios

Respuesta para el campo de 300 caracteres (262 caracteres):

> Centraliza clientes, obras, visitas, jornadas, notas y recordatorios para registrar y consultar la actividad desde el móvil. Permite adjuntar fotos y ubicación a las visitas, y registrar ciertas operaciones sin conexión para sincronizarlas al recuperar Internet.

### Instalaciones estimadas durante el primer año

En la captura de Yely aparece seleccionada la opción **«entre 0 y 10.000»**. Confirmar que refleja su previsión real antes de continuar; no deducirla de los 20 correos invitados a la prueba.

## 3. Preparación para producción

### Cambios realizados a partir de la prueba

Respuesta para el campo de 300 caracteres (287 caracteres):

> El feedback llevó a traducir textos del historial, actualizar inmediatamente el avance de obras y el estado de clientes en los listados, aclarar el mensaje de asignación de vendedor y validar el formato de correo. Esos cambios se incluyeron en la versión 1.0.0 (16) de la prueba cerrada.

El reporte posterior sobre una nota de obra muy larga motivó una protección adicional en el código; esta última corrección aún no se ha distribuido ni probado en un Android real y, por ello, no figura entre los cambios distribuidos.

### ¿Cómo se determinó que está lista para producción?

**No responder afirmativamente todavía.** La corrección del error de notas pasa 150 pruebas Flutter y `dart analyze lib test`; CI generó y verificó el AAB firmado `1.0.0 (17)`. En un Galaxy S10, la cuenta de demostración inició sesión, el formulario limitó a 2.000 caracteres un ingreso de 2.200, guardó una nota de 2.000, la mostró tras reiniciar y Sincronización indicó que no había pendientes. Las 9 pruebas de pantallas de clientes y obras volvieron a aprobar. El reintento ante un error de servidor está cubierto por prueba automatizada, pero no se reprodujo físicamente. El build 17 aún no se entregó a testers mediante Google Play; no afirmar que el error del backend quedó resuelto.

## Decisiones y evidencia pendientes

1. Yely confirma que «entre 0 y 10.000» es su estimación intencional para el primer año.
2. El AAB Android `1.0.0 (17)` ya se generó y verificó en CI; el límite y guardado de notas se probaron en el Galaxy S10. Falta distribuirlo en la prueba cerrada de Play y verificar la actualización desde esa vía antes de considerarlo candidato de producción.
3. Antes de «Aplicar», ambas partes revisan las respuestas finales y la estabilidad de la versión candidata. Google revisa el acceso a producción por separado de la publicación pública.
