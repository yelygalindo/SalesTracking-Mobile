# UrbanTrack Mobile

Aplicación Flutter para el seguimiento comercial y operativo en campo.

## Requisitos

- Flutter 3.44.9 o compatible
- Dart 3.12 o compatible
- Android SDK para compilar Android
- macOS con Xcode, o un servicio de CI macOS, para compilar y firmar iOS

## Ejecución

```powershell
flutter pub get
flutter run --dart-define=API_BASE_URL=https://salestracking-api.kindriver-61f4971f.brazilsouth.azurecontainerapps.io
```

La URL pública actual de la API es el valor predeterminado. `API_BASE_URL` permite sustituirla por un entorno de pruebas o producción sin cambiar el código.

## Identificadores

- Android: `io.urbantrack.app`
- iOS: `io.urbantrack.app`

## Arquitectura inicial

El proyecto sigue una separación por responsabilidades:

- `lib/ui`: pantallas, componentes, tema y configuración visual de marca.
- `lib/data`: servicios remotos/locales y repositorios (se incorporarán por módulo).
- `lib/domain`: casos de uso compartidos cuando la complejidad lo justifique.
- `lib/config`: parámetros de entorno no sensibles.

La marca está desacoplada en `lib/ui/core/branding`. UrbanTrack es la distribución inicial. Una futura marca puede aportar otro `BrandConfig` y recursos propios sin modificar la lógica de clientes, obras, visitas o sincronización.

## Secretos

No se deben versionar usuarios, contraseñas, tokens, certificados ni llaves de firma. Las credenciales de prueba se suministran localmente durante la ejecución y los archivos habituales de secretos están excluidos por `.gitignore`.

## Estado

- Scaffold Android/iOS e identificadores nativos configurados.
- Branding visual desacoplado con UrbanTrack como distribución inicial.
- Login conectado a `/api/auth/login` con manejo de errores.
- Sesión y token de actualización almacenados de forma segura.
- Restauración, rotación de tokens y cierre de sesión implementados.
- Pruebas de modelos, servicio REST, repositorio, view model y pantalla inicial.

Los flujos de recuperación de contraseña, jornada y módulos comerciales se implementarán en los siguientes hitos.
