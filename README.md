# UrbanTrackCRM Mobile

MVP móvil en Flutter para seguimiento comercial y operativo en campo. Comparte una sola base de código para Android e iOS y consume la API REST de UrbanTrack.

## Requisitos

- Flutter 3.44.9 o compatible
- Dart 3.12 o compatible
- Android SDK para ejecutar o compilar Android
- macOS con Xcode, o CI con runner macOS, para compilar iOS

## Configuración y ejecución

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=https://salestracking-api.kindriver-61f4971f.brazilsouth.azurecontainerapps.io
```

La URL pública actual es el valor predeterminado. `API_BASE_URL` permite apuntar a otro entorno sin modificar el código.

No se deben versionar usuarios, contraseñas, tokens, certificados ni llaves de firma. Las credenciales se introducen en la aplicación durante las pruebas y la sesión se conserva mediante almacenamiento seguro del dispositivo.

## Verificación y builds

```powershell
flutter analyze
flutter test
flutter build apk --release
```

Para validar en un dispositivo Android el recorrido principal sin usar cuentas
ni datos reales de la API:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_navigation_test.dart -d <device-id>
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/customer_lifecycle_test.dart -d <device-id>
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/workday_lifecycle_test.dart -d <device-id>
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/visit_lifecycle_test.dart -d <device-id>
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/project_photo_lifecycle_test.dart -d <device-id>
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/project_lifecycle_test.dart -d <device-id>
```

Para comprobar la captura de GPS real sin escribir datos en la API, usa un
dispositivo físico con ubicación activa y permisos de ubicación concedidos:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/real_gps_workday_test.dart -d <device-id>
```

Esta prueba usa repositorios en memoria; ninguna jornada ni coordenada se envía
al servidor.

Los estados nativos de error también tienen recorridos reproducibles:

```powershell
# Ejecutar con la ubicación del dispositivo temporalmente desactivada.
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/location_services_disabled_test.dart -d <device-id>

# Ejecutar sin permisos previos y elegir "No permitir" en el diálogo nativo.
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/location_permission_denied_test.dart -d <device-id>
```

En ambos casos la jornada debe permanecer cerrada y la interfaz debe explicar
cómo corregir el problema. Restaura la ubicación del dispositivo después del
primer recorrido.

En Windows, las herramientas Android pueden fallar con `Illegal byte sequence`
si la ruta del proyecto contiene caracteres acentuados. En ese caso, ejecutar
los comandos desde un clon o enlace de directorio cuya ruta use únicamente
caracteres ASCII; no es necesario duplicar el proyecto.

Para comprobar que el Swagger aún conserva los endpoints, parámetros y campos consumidos por la aplicación:

```powershell
dart run tool/verify_openapi_contract.dart
```

Este chequeo consulta únicamente el documento OpenAPI público; no usa usuarios, contraseñas ni tokens.

Para comprobar autenticación y consultas reales sin crear ni modificar datos,
el smoke test autenticado lee las credenciales solo desde variables de entorno.
En PowerShell, `Get-Credential` evita que la contraseña quede visible:

```powershell
$smokeCredential = Get-Credential
$env:URBANTRACK_SMOKE_EMAIL = $smokeCredential.UserName
$env:URBANTRACK_SMOKE_PASSWORD = $smokeCredential.GetNetworkCredential().Password
dart run tool/verify_live_api.dart
Remove-Item Env:URBANTRACK_SMOKE_EMAIL, Env:URBANTRACK_SMOKE_PASSWORD
```

El comando valida login, jornada y visita actuales, catálogos, clientes, obras,
historial y opciones de adjuntos. Solo ejecuta `GET` después del login y nunca
imprime credenciales, tokens ni cuerpos de respuesta.

La autenticación admite hasta 45 segundos porque el contenedor público puede
necesitar más de 20 segundos para responder después de un arranque en frío.

En macOS:

```bash
flutter build ios --release --no-codesign
```

Para firmar y distribuir iOS se requiere configurar el equipo de Apple Developer en Xcode. Para publicar Android se debe proporcionar un keystore de producción y su configuración local; esos secretos no deben subirse al repositorio.

### Comprobación iOS sin Mac local

El workflow manual `.github/workflows/ios-compile.yml` compila una aplicación para el simulador iOS en un runner macOS:

1. Abrir **Actions** en GitHub.
2. Seleccionar **iOS compile check**.
3. Pulsar **Run workflow**.
4. Descargar el artefacto `urbantrackcrm-ios-simulator` al finalizar.

No se ejecuta con cada push para evitar consumo accidental. En repositorios privados, los runners macOS usan la cuota incluida de GitHub Actions y el uso adicional tiene una tarifa mayor que Linux; se debe revisar el consumo antes de lanzarlo. El artefacto confirma que el proyecto compila para iOS, pero no se instala en un iPhone físico. Para probar en el iPhone y distribuir con TestFlight todavía se requieren la membresía Apple Developer, certificados y perfiles de aprovisionamiento.

El workflow usa `macos-26` porque la versión actual de `connectivity_plus` compila contra APIs recientes de `Network.framework`. Un runner con un SDK de Xcode anterior puede fallar aunque el código Dart y las pruebas sean correctos.

Identificadores actuales:

- Android: `io.urbantrack.crm.app`
- iOS: `io.urbantrack.crm.app`

El procedimiento de QA, firma, pruebas cerradas, TestFlight y publicación está
documentado en [`docs/qa-and-release-runbook.md`](docs/qa-and-release-runbook.md).

## Funcionalidades implementadas

- Login, cierre de sesión, persistencia segura y renovación de tokens.
- Solicitud y confirmación de restablecimiento de contraseña.
- Inicio y cierre de jornada con hora móvil y ubicación GPS.
- Listado, detalle, creación y edición de clientes.
- Estados de clientes, notas y recordatorios.
- Listado, detalle, creación y edición de obras.
- Notas e historial cronológico dentro del detalle de cada obra.
- Consulta offline de clientes y obras previamente sincronizados.
- Check-in/check-out de visitas a clientes y obras con hora, GPS, notas, resultado y duración.
- Cámara y galería para evidencias fotográficas asociadas a visitas de obra.
- Historial personal por fecha y listado de visitas por obra.
- Pantalla de operaciones pendientes y reintento manual.
- Sincronización automática al recuperar conectividad.
- Diseños adaptables a teléfonos y pantallas de mayor ancho.

## Funcionamiento offline

Las operaciones críticas no dependen de mantener la pantalla o la aplicación abierta. Se guardan primero en SQLite con un identificador de solicitud estable y luego se sincronizan respetando sus dependencias:

1. Inicio/cierre de jornada.
2. Creación de clientes.
3. Check-in/check-out de visitas.
4. Fotografías vinculadas a visitas de obra.

Los IDs locales de visitas se reconcilian con los IDs definitivos del servidor antes de enviar operaciones dependientes. Las fotografías seleccionadas se copian al almacenamiento privado de la aplicación antes de encolarse. Como el endpoint de adjuntos no recibe `clientRequestId`, los reintentos comparan nombre estable, tamaño y visita remota antes de volver a cargar el archivo para evitar duplicados.

## Permisos del dispositivo

La aplicación solicita ubicación cuando una jornada o visita requiere capturar GPS. En iOS están declarados los mensajes de uso de cámara y fototeca. Android no requiere configuración adicional para `image_picker`; las fotos tomadas se copian desde la caché a almacenamiento persistente antes de sincronizarse.

## Arquitectura

- `lib/ui`: pantallas, view models, tema y componentes visuales.
- `lib/data/models`: contratos y modelos de dominio usados por la aplicación.
- `lib/data/services`: integración HTTP con los endpoints documentados.
- `lib/data/repositories`: coordinación remota/local y estrategias offline-first.
- `lib/data/storage`: sesión segura, SQLite y archivos pendientes.
- `lib/config`: parámetros no sensibles por entorno.

La marca está desacoplada en `lib/ui/core/branding`. UrbanTrackCRM es la distribución inicial; otra distribución puede proporcionar un `BrandConfig`, nombre y recursos propios sin modificar la lógica de clientes, obras, visitas o sincronización.

## Consideraciones actuales de la API

- La app obtiene los estados de obra desde `GET /api/projects/statuses`, los conserva localmente para consulta sin conexión y utiliza sus IDs al invocar `PATCH /api/projects/{externalId}/status`.
- El historial personal consume `/api/sellers/{sellerExternalId}/timeline`. Se conserva `/api/visits` como respaldo de compatibilidad ante fallos transitorios o despliegues anteriores de la API.
- La activación de enlaces HTTPS desde correos de recuperación requiere publicar los archivos de asociación de Android/iOS en `urbantrack.io`. Mientras tanto, el token se puede pegar manualmente en la pantalla de restablecimiento.
