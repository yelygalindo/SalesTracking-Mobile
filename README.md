# UrbanTrack Mobile

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
4. Descargar el artefacto `urbantrack-ios-simulator` al finalizar.

No se ejecuta con cada push para evitar consumo accidental. En repositorios privados, los runners macOS usan la cuota incluida de GitHub Actions y el uso adicional tiene una tarifa mayor que Linux; se debe revisar el consumo antes de lanzarlo. El artefacto confirma que el proyecto compila para iOS, pero no se instala en un iPhone físico. Para probar en el iPhone y distribuir con TestFlight todavía se requieren la membresía Apple Developer, certificados y perfiles de aprovisionamiento.

Identificadores actuales:

- Android: `io.urbantrack.app`
- iOS: `io.urbantrack.app`

## Funcionalidades implementadas

- Login, cierre de sesión, persistencia segura y renovación de tokens.
- Solicitud y confirmación de restablecimiento de contraseña.
- Inicio y cierre de jornada con hora móvil y ubicación GPS.
- Listado, detalle, creación y edición de clientes.
- Estados de clientes, notas y recordatorios.
- Listado, detalle, creación y edición de obras.
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

La marca está desacoplada en `lib/ui/core/branding`. UrbanTrack es la distribución inicial; otra distribución puede proporcionar un `BrandConfig`, nombre y recursos propios sin modificar la lógica de clientes, obras, visitas o sincronización.

## Consideraciones actuales de la API

- El Swagger expone `PATCH /api/projects/{externalId}/status` con un `statusId` numérico, pero no publica un catálogo equivalente a `/api/customers/statuses`. La app puede filtrar los estados de obra definidos por producto; el cambio de estado se habilitará cuando el backend entregue los IDs o un endpoint de catálogo.
- El usuario vendedor de pruebas recibe `403` al consultar su propio `/api/sellers/{sellerExternalId}/timeline`. La app usa automáticamente `/api/visits` como respaldo para mantener visible el historial de visitas. Cuando el backend habilite el permiso del timeline, se mostrarán además los demás tipos de actividad sin cambios en el cliente.
- La activación de enlaces HTTPS desde correos de recuperación requiere publicar los archivos de asociación de Android/iOS en `urbantrack.io`. Mientras tanto, el token se puede pegar manualmente en la pantalla de restablecimiento.
