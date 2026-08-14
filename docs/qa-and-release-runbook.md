# UrbanTrackCRM: QA y publicación

Este runbook define qué debe estar listo antes de distribuir el MVP, cómo
validarlo y qué responsabilidades corresponden al cliente y al desarrollo.
No sustituye los formularios ni las revisiones de Google Play o Apple.

## Estado actual

- [x] Identificadores Android e iOS: `io.urbantrack.crm.app`.
- [x] Compilación Android de depuración validada en un dispositivo real.
- [x] Compilación iOS para simulador validada en GitHub Actions.
- [x] Contrato público OpenAPI verificado automáticamente.
- [x] Login y consultas de clientes, obras, visitas, historial y adjuntos
      validados contra la API publicada.
- [x] Acceso del vendedor a `GET /api/workdays/current` corregido y validado
      contra la API publicada.
- [x] Ciclo de interfaz iniciar/cerrar jornada validado en emulador Android con
      hora móvil, ubicación inyectada e identificadores de solicitud únicos.
- [ ] Comprobar en dispositivo el ciclo completo de inicio/cierre de jornada
      con ubicación GPS.
- [ ] Recibir e integrar logotipo, icono y recursos definitivos.
- [ ] Completar y verificar las cuentas de Google Play y Apple Developer.
- [ ] Configurar claves de firma de producción; actualmente Android `release`
      usa deliberadamente la clave de depuración y no debe publicarse.
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
| Obras | Listar, filtrar, ver detalle, crear, editar, estado, nota e historial |
| Visitas | Check-in/out de cliente y obra, GPS, duración, resultado y notas |
| Evidencias | Cámara, galería, varias fotos, foto pendiente y reintento |
| Offline | Pérdida de red, cierre de app, cola persistente, orden de dependencias y no duplicación |
| Historial | Fecha, orden cronológico, datos de visita y estados vacío/error |
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

- [ ] Cuenta de desarrollador completamente verificada.
- [ ] Aplicación creada con `io.urbantrack.crm.app`.
- [ ] Ficha, icono, capturas, política de privacidad y formularios completos.
- [ ] Upload key propiedad del cliente, respaldada y configurada localmente.
- [ ] Play App Signing habilitado.
- [ ] `version` y build number incrementados en `pubspec.yaml`.
- [ ] AAB de release firmado; no usar el APK ni la clave de depuración.

Build final:

```powershell
flutter build appbundle --release
```

El artefacto esperado es `build/app/outputs/bundle/release/app-release.aab`.
Google Play exige Android App Bundles para aplicaciones nuevas y el bundle debe
estar firmado con la upload key antes de cargarlo.

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

- [ ] Membresía Apple Developer activa y acuerdos aceptados.
- [ ] Bundle ID y registro de App Store Connect para `io.urbantrack.crm.app`.
- [ ] Acceso del desarrollador con rol Developer o App Manager, según la tarea.
- [ ] Certificados/perfiles administrados por Xcode o credenciales de CI seguras.
- [ ] Información beta, correo de feedback, privacidad y export compliance.
- [ ] Iconos y recursos definitivos integrados.
- [ ] Build number nuevo para cada carga.

El workflow actual solo genera una app de simulador sin firma. No puede
instalarse en un iPhone ni cargarse a TestFlight. Una vez activada la cuenta de
Apple se configurará un build firmado en una Mac o en CI; certificados, API
keys y perfiles se guardarán como secretos y nunca en Git.

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

## Liberación y reversión

Una versión solo puede promoverse si no hay defectos bloqueantes, el smoke de
API pasa y los flujos críticos fueron aprobados. Si aparece un defecto durante
la prueba, detener la promoción, conservar el build anterior disponible,
corregir en Git, incrementar el build number y distribuir un artefacto nuevo.
Nunca sobrescribir o reutilizar el número de un build ya cargado.
