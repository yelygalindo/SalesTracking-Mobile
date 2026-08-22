# Google Play: borrador de declaraciones del MVP

Este documento prepara las respuestas de Play Console para **UrbanTrackCRM
1.0**. No sustituye la aprobación del titular de la cuenta ni constituye una
declaración legal. Yely debe confirmar las respuestas antes de guardarlas o
enviarlas a revisión.

No se deben anunciar ni declarar como implementadas funciones de una versión
posterior: tracking continuo con Traccar, entregas de productos, archivos de
ofimática, videos, proyectos sin cliente u otras ampliaciones fuera del MVP.

## Respuestas propuestas

| Sección de Play Console | Respuesta propuesta para 1.0 | Evidencia o condición |
| --- | --- | --- |
| Política de privacidad | `https://urbantrack.io/privacy` | URL HTTPS validada y guardada en el borrador de Play Console. |
| Acceso a la app | Todas las funciones requieren autenticación | Crear una cuenta exclusiva para revisión, de rol vendedor, que permanezca activa durante la revisión. No documentar credenciales en Git. |
| Anuncios | No contiene anuncios | No existen SDK ni dependencias de publicidad en el proyecto. |
| Público objetivo | Solo adultos; no dirigida a menores | Aplicación empresarial para equipos comerciales. El titular debe confirmar el rango exacto solicitado por Play. |
| App gubernamental | No | Producto comercial privado. |
| Funciones financieras | Ninguna | El monto estimado de una obra es información comercial; la app no ofrece pagos, banca, crédito, inversión ni activos digitales. |
| Salud | No ofrece funciones de salud | No procesa métricas ni presta servicios médicos o de bienestar. |
| Categoría | Empresa / Productividad | Preferencia propuesta: **Empresa**. Confirmar antes de guardar. |
| Sitio web | `https://urbantrack.io` | Dominio oficial confirmado por el cliente. |
| Correo de soporte | `support@urbantrack.io` | Ya figura como contacto de privacidad; confirmar que el buzón es atendido. |

## Seguridad de los datos

La declaración debe describir el comportamiento real del MVP y también el
tratamiento realizado por la API. Propuesta técnica para revisión del titular:

| Tipo de dato | ¿Se recopila? | Uso principal |
| --- | --- | --- |
| Nombre, correo e identificadores de usuario | Sí | Autenticación, cuenta y asignación de actividad. |
| Datos de clientes: nombre, empresa, teléfono, correo y dirección | Sí | Gestión comercial solicitada por la organización. |
| Ubicación precisa | Sí, cuando el usuario inicia/cierra jornadas o visitas | Funcionalidad principal de trabajo en campo. No existe tracking continuo en 1.0. |
| Fotografías | Sí, cuando el usuario decide adjuntarlas a una visita de obra | Evidencia de la actividad; cámara o selector del sistema. |
| Notas, recordatorios, estados, jornadas y visitas | Sí | Contenido empresarial generado por el usuario y operación del CRM. |
| Contraseña | Se transmite para autenticar; no se conserva en texto plano en la app | Seguridad de la cuenta. La app guarda tokens en almacenamiento seguro. |
| Datos de fallos, analítica o publicidad | No mediante SDK en la app | No hay Firebase Analytics, Crashlytics ni SDK publicitario integrados. Confirmar cualquier registro adicional del backend. |
| Videos, Excel u otros documentos | No en 1.0 | Funciones reservadas para una etapa posterior. |
| Tracking continuo / Traccar | No en 1.0 | Función reservada para una etapa posterior. |

La transmisión a la API utiliza HTTPS. La aplicación guarda temporalmente en
el dispositivo datos operativos y fotografías pendientes para permitir el
modo offline, y conserva la sesión mediante almacenamiento seguro.

Antes de responder si los datos se **comparten** con terceros, el titular debe
confirmar que Azure, almacenamiento de fotografías, correo y otros proveedores
actúan únicamente como proveedores de servicio bajo sus instrucciones. La
clasificación de Google distingue ese procesamiento de otros usos o
transferencias de datos.

## Confirmaciones necesarias de Yely

1. Aprobar que la audiencia sea exclusivamente adulta y que la categoría sea
   **Empresa**.
2. Confirmar que la aplicación no contiene publicidad ni funciones de salud,
   gobierno o servicios financieros.
3. Confirmar los proveedores que procesan datos en backend y que no se venden
   ni se utilizan para publicidad.
4. Confirmar que `support@urbantrack.io` recibe solicitudes y soporte.
5. Crear un usuario vendedor exclusivo para la revisión de Google, con datos
   de demostración y acceso estable. Las credenciales se cargarán únicamente en
   el formulario privado de acceso a la app.
6. Aprobar el inventario de datos anterior y cualquier política interna de
   conservación o eliminación aplicable.

## Materiales pendientes de la ficha

- Nombre visible: `UrbanTrackCRM`.
- Descripción breve propuesta (74 de 80 caracteres):

  > Gestiona clientes, obras, visitas y jornadas comerciales en un solo lugar.

- Descripción completa propuesta (1,085 de 4,000 caracteres):

  > UrbanTrackCRM ayuda a los equipos comerciales a organizar y dar seguimiento
  > al trabajo en campo desde una sola aplicación.
  >
  > Consulta y actualiza la información necesaria para mantener clientes, obras
  > y visitas bajo control.
  >
  > Con UrbanTrackCRM puedes:
  >
  > - Gestionar clientes y sus datos de contacto.
  > - Crear y consultar obras o proyectos.
  > - Registrar notas y recordatorios.
  > - Actualizar el estado comercial de clientes y obras.
  > - Consultar el historial de actividades y visitas.
  > - Iniciar y finalizar jornadas de trabajo.
  > - Registrar visitas mediante check-in y check-out.
  > - Guardar el resultado, la duración, las notas y la ubicación de cada visita.
  > - Ver clientes y obras en el mapa.
  > - Adjuntar fotografías a visitas de obras.
  > - Registrar operaciones críticas sin conexión y sincronizarlas cuando se
  >   restablezca Internet.
  >
  > Las cuentas de UrbanTrackCRM son creadas y administradas por la empresa u
  > organización que utiliza el servicio. Si tu empresa usa UrbanTrackCRM,
  > inicia sesión con las credenciales que te haya proporcionado.
  >
  > UrbanTrackCRM: clientes, obras y visitas bajo control.

  Los datos de soporte, sitio web y privacidad se completan en sus campos
  específicos de Play Console y no necesitan repetirse en la descripción.

- Icono de alta resolución, gráfico de funciones y capturas para teléfono.
- Textos o capturas futuras se actualizarán como parte de la versión a la que
  correspondan; no se anticiparán funciones no incluidas en este hito.
