# Enlaces de restablecimiento de contraseña

La aplicación reconoce internamente la ruta:

```text
/reset-password?token=<token>
```

El formulario también permite pegar el token manualmente, por lo que el flujo puede utilizarse antes de habilitar enlaces universales.

## Pendiente para enlaces HTTPS

Para abrir `https://urbantrack.io/reset-password?token=...` directamente en la aplicación se necesita:

1. Definir esa URL en la plantilla de correo del backend.
2. Publicar `/.well-known/assetlinks.json` en el dominio con `io.urbantrack.crm.app` y el certificado SHA-256 de la firma Android de producción.
3. Publicar `/.well-known/apple-app-site-association` con el Apple Team ID y `io.urbantrack.crm.app`.
4. Agregar el dominio asociado a los entitlements de iOS y el intent filter verificado de Android.
5. Validar el enlace en dispositivos reales después de crear las cuentas y certificados de publicación.

No se agregan asociaciones incompletas en esta etapa porque todavía no existen los identificadores criptográficos definitivos de las tiendas.
