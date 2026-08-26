# UrbanTrackCRM: QA y publicación

Este runbook define qué debe estar listo antes de distribuir el MVP, cómo
validarlo y qué responsabilidades corresponden al cliente y al desarrollo.
No sustituye los formularios ni las revisiones de Google Play o Apple.

## Estado actual

- [x] Identificadores Android e iOS: `io.urbantrack.crm.app`.
- [x] Compilación Android de depuración validada en un dispositivo real.
- [x] APK Android `release` con firma temporal de depuración validado en frío
      en un Galaxy A21s de 720x1600: paquete `io.urbantrack.crm.app`, versión
      `1.0.0+8` y pantalla de acceso sin errores nativos ni desbordes.
- [x] Compilación iOS para simulador validada en GitHub Actions.
- [x] Contrato público OpenAPI verificado automáticamente.
- [x] Login y consultas de clientes, obras, visitas, historial y adjuntos
      validados contra la API publicada.
- [x] Contratos y consultas de recordatorios de clientes y obras validados;
      las altas se autoasignan al usuario autenticado cuando no existe una
      selección administrativa.
- [x] Acceso del vendedor a `GET /api/workdays/current` corregido y validado
      contra la API publicada.
- [x] Ciclo de interfaz iniciar/cerrar jornada validado en emulador Android con
      hora móvil, ubicación inyectada e identificadores de solicitud únicos.
- [x] Ciclo de interfaz check-in/check-out de cliente validado en emulador
      Android con resultado opcional, opciones rápidas, notas, hora móvil,
      ubicación inyectada e identificadores de solicitud únicos.
- [x] Gestión completa de clientes validada en emulador Android: alta con
      ubicación inyectada, edición, estado, nota, recordatorio y finalización.
- [x] Visita de obra con fuentes simuladas de cámara y galería validada en
      emulador Android: los archivos quedan persistidos y encolados sin conexión
      con dependencia explícita del check-in pendiente.
- [x] Cámara y galería nativas validadas en un Galaxy S10 físico: cada archivo
      real contiene datos, se copia al almacenamiento privado y queda encolado
      sin enviar información a la API. La consulta del intent de cámara para
      Android 11+ evita archivos vacíos en la cámara Samsung.
- [x] Gestión completa de obras validada en un dispositivo Android real: alta
      con validaciones y ubicación inyectada, edición, estado, nota, historial y
      visita con check-in/check-out, resultado, notas y ubicación.
- [x] Notas y recordatorios de clientes y obras validados sin conexión: quedan
      visibles en caché, conservan su identificador idempotente y se reproducen
      en orden al recuperar conectividad.
- [x] Filtros de clientes y obras validados con los códigos/IDs aceptados por la
      API; edición validada con `expectedUpdatedAtUtc` y correo de cliente
      opcional.
- [x] Ciclo completo de inicio/cierre de jornada con GPS real validado en dos
      dispositivos Android físicos, utilizando repositorios en memoria para no
      transmitir coordenadas ni crear datos en la API.
- [x] Errores reales de ubicación validados en Android: servicio GPS desactivado
      y permiso rechazado desde el diálogo nativo mantienen la jornada cerrada
      y muestran una instrucción recuperable al vendedor.
- [x] Navegación principal autenticada y cierre de sesión validados con
      repositorios aislados en un Galaxy A21s físico de 720x1600.
- [x] Logotipo, icono, paleta y tipografía definitivos integrados.
- [x] Cuenta de Google Play verificada y aplicación `UrbanTrackCRM` creada en
      estado borrador con el paquete correcto.
- [x] Política de privacidad publicada en `https://urbantrack.io/privacy`.
- [x] Membresía Apple Developer activa, acuerdos aceptados y aplicación
      `UrbanTrackCRM` creada en App Store Connect con el bundle ID correcto.
- [x] Clave de equipo de App Store Connect configurada como secretos cifrados
      de GitHub Actions; el archivo privado no está versionado.
- [x] Upload key creada y configurada localmente fuera del repositorio; los
      builds `release` fallan si intentan ejecutarse sin esa configuración.
- [x] AAB firmado `1.0.0+13` validado con Bundletool: paquete
      `io.urbantrack.crm.app`, SHA-256
      `11D5B7313219241F9621E14BB617A6CED256B8957259EAB74D09BCE97F47E83F`.
- [x] AAB `1.0.0 (13)` validado por Google Play y guardado como borrador de
      prueba interna con el nombre `1.0.0 (13) - MVP`; no se inició la
      distribución a testers.
- [ ] Entregar al titular el respaldo de la upload key y sus credenciales por
      canales separados y confirmar su conservación segura.
- [ ] Publicar los archivos de asociación de enlaces de contraseña descritos
      en `docs/password-reset-links.md`.

## Responsabilidades

### Yely / titular de las cuentas

- Mantener la titularidad y recuperación de Google Play Console, Apple
  Developer, App Store Connect y el dominio `urbantrack.io`.
- Completar verificaciones de identidad, acuerdos y pagos de las plataformas.
- Invitar al desarrollador con el rol mínimo necesario; no compartir la
  contraseña principal ni códigos de doble factor.
- Proporcionar nombre, icono, logotipo, capturas, descripción, categoría,
  correo de soporte y URL de política de privacidad definitivos.
- Aprobar las declaraciones de privacidad, seguridad de datos, contenido y
  audiencia antes de enviarlas a revisión.
- Reunir al menos 12 testers Android; se recomiendan 15 como margen.
- Conservar de forma segura las claves de firma y sus respaldos.

### Desarrollo

- Integrar los recursos aprobados sin acoplarlos a la lógica del producto.
- Ejecutar análisis, pruebas, smoke de API y builds antes de cada entrega.
- Configurar la firma mediante archivos y secretos locales no versionados.
- Generar el AAB Android y el archivo iOS firmado cuando existan los accesos.
- Acompañar la carga, pruebas cerradas/TestFlight y correcciones del alcance.
- No decidir en nombre del titular las declaraciones legales o de privacidad.

## Puerta de QA funcional

Ejecutar cada caso en Android y repetir los flujos críticos en iOS/TestFlight
cuando exista un build firmado. Registrar dispositivo, versión, fecha y
resultado; no adjuntar tokens ni contraseñas en capturas.

| Área | Casos mínimos |
| --- | --- |
| Autenticación | Login válido/inválido, sesión persistente, logout, recuperación de contraseña |
| Permisos | Ubicación concedida/denegada, cámara y galería concedidas/denegadas |
| Jornada | Inicio y cierre online, hora móvil y hora recibida, cierre después de reiniciar la app |
| Clientes | Listar, buscar, filtrar, ver detalle, crear, editar, estado, nota y recordatorio |
| Obras | Listar, filtrar, ver detalle, crear, editar, estado, nota, recordatorio e historial |
| Visitas | Check-in/out de cliente y obra, GPS, duración, resultado y notas |
| Evidencias | Cámara, galería, varias fotos, foto pendiente y reintento |
| Offline | Pérdida de red, cierre de app, cola persistente, orden de dependencias y no duplicación |
| Historial | Fecha, orden cronológico, datos de visita, miniaturas y estados vacío/error |
| Accesibilidad | Etiquetas, contraste, objetivos táctiles y ausencia de desbordes |

Comandos técnicos previos:

```powershell
flutter pub get
flutter analyze
flutter test
dart run tool/verify_openapi_contract.dart
flutter build apk --debug
```

El smoke autenticado de `README.md` debe terminar sin fallos antes de probar
mutaciones reales. Los datos creados para QA deben llevar nombres reconocibles
y contar con autorización del cliente si el entorno no dispone de eliminación.

## Google Play

### Preparación

- [x] Cuenta de desarrollador completamente verificada.
- [x] Aplicación creada con `io.urbantrack.crm.app`.
- [ ] Ficha, icono, capturas y formularios completos; la política de privacidad
      ya está guardada en Play Console.
- [ ] Upload key respaldada bajo control del cliente; ya está creada y
      configurada localmente, pero falta confirmar la entrega segura.
- [x] Play App Signing habilitado.
- [x] `version` y build number incrementados a `1.0.0+13` en `pubspec.yaml`.
- [x] AAB de release firmado y validado; no usa el APK ni la clave de
      depuración.
- [x] Primera versión cargada y guardada únicamente como borrador en la pista
      de prueba interna.

Build final:

```powershell
flutter build appbundle --release
```

El artefacto esperado es `build/app/outputs/bundle/release/app-release.aab`.
Google Play exige Android App Bundles para aplicaciones nuevas y el bundle debe
estar firmado con la upload key antes de cargarlo.

La configuración local parte de `android/key.properties.example`. El archivo
real y el keystore están excluidos de Git; las contraseñas no deben escribirse
en comandos, documentación, commits ni mensajes compartidos. Antes de cargar
el AAB, conservar un respaldo seguro bajo control del titular de la cuenta.

Las respuestas propuestas para los formularios de contenido y seguridad están
en [`google-play-declarations-draft.md`](google-play-declarations-draft.md). El
titular debe aprobarlas antes de guardarlas o enviarlas a revisión.

### Prueba cerrada de la cuenta personal

1. Crear una pista de prueba cerrada y cargar el AAB aprobado.
2. Añadir las cuentas Google de los testers y compartir el enlace de adhesión.
3. Confirmar al menos 12 testers inscritos; mantener 15 invitados como margen.
4. Mantener un mínimo de 12 inscritos durante 14 días consecutivos.
5. Recoger comentarios reales y registrar las correcciones realizadas.
6. Solicitar acceso a producción y responder las preguntas de Google Play.

Referencia oficial: [requisitos de prueba para cuentas personales nuevas](https://support.google.com/googleplay/android-developer/answer/14151465)
y [firma de aplicaciones Android](https://developer.android.com/studio/publish/app-signing).

## Apple / TestFlight

### Preparación

- [x] Membresía Apple Developer activa y acuerdos aceptados.
- [x] Bundle ID y registro de App Store Connect para `io.urbantrack.crm.app`.
- [x] Acceso del desarrollador a App Store Connect con rol Administración.
- [x] Credenciales de la clave de equipo guardadas en GitHub Actions Secrets.
- [ ] Certificado y perfil administrados automáticamente durante el primer build
      firmado en CI.
- [ ] Información beta, correo de feedback, privacidad y export compliance.
- [x] Iconos y recursos definitivos integrados.
- [ ] Build number nuevo para cada carga.

El workflow `ios-compile.yml` solo genera una app de simulador sin firma. El
workflow manual `ios-testflight.yml` prepara el archive y el IPA firmado usando
la clave de equipo almacenada como secreto. La opción de carga a TestFlight
permanece desactivada de forma predeterminada para separar la validación del IPA
de la acción de transmitirlo a Apple.

Flujo de entrega:

1. Crear el registro de la app en App Store Connect.
2. Generar y cargar un build firmado.
3. Esperar el procesamiento de Apple y resolver avisos de cumplimiento.
4. Distribuir primero a testers internos de TestFlight.
5. Corregir fallos y, si se requieren externos, enviar la beta a revisión.
6. Seleccionar el build aprobado y enviarlo posteriormente a App Review.

Referencias oficiales: [flujo de App Store Connect](https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-workflow),
[carga de builds](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)
y [TestFlight](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/).

## Seguridad operativa

- No publicar capturas que muestren access tokens, refresh tokens, contraseñas,
  cookies, claves o códigos de recuperación.
- Revocar inmediatamente cualquier sesión o secreto que aparezca en una
  captura compartida, incluso en canales privados.
- No versionar `.env`, `key.properties`, keystores, certificados ni API keys.
- Limitar accesos a cuentas y repositorio a las personas necesarias.
- Retirar testers y accesos temporales al finalizar la publicación.
- Revocar la clave temporal `UrbanTrackCRM CI temporal` cuando ya no sea
  necesaria para builds o publicación automatizada.

## Liberación y reversión

Una versión solo puede promoverse si no hay defectos bloqueantes, el smoke de
API pasa y los flujos críticos fueron aprobados. Si aparece un defecto durante
la prueba, detener la promoción, conservar el build anterior disponible,
corregir en Git, incrementar el build number y distribuir un artefacto nuevo.
Nunca sobrescribir o reutilizar el número de un build ya cargado.
