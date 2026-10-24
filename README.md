# LethorPos - Descargas

Descargas oficiales de LethorPos, el punto de venta de LETHORSOFT, para Windows y Android.

**[Descargar la última versión](https://github.com/pc2x/Lethorpos-releases/releases/latest)**

Las versiones anteriores están en la sección [Releases](https://github.com/pc2x/Lethorpos-releases/releases).

## ¿Qué archivo descargo?

| Si usted quiere... | Descargue |
| --- | --- |
| Instalar LethorPos por primera vez en una computadora con Windows | `LethorPos-Setup-v{version}.exe` |
| Actualizar una computadora con Windows que ya tiene LethorPos | `LethorPos-Update-v{version}.exe` |
| Usar una tableta o celular Android como punto de venta principal (servidor) | `LethorPos-Android-v{version}.apk` |
| Usar otra computadora con Windows como caja o terminal adicional | `LethorPos-Cliente-Windows-v{version}.exe` |
| Usar otra tableta o celular Android como terminal adicional | `LethorPos-Cliente-Android-v{version}.apk` |

El **servidor** es el equipo principal donde se guarda la información del negocio (ventas, productos, usuarios).
Los **clientes** son terminales adicionales que se conectan a ese servidor por la red local; no guardan datos propios.

## Requisitos

- **Windows:** Windows 10 u 11 de 64 bits. Se necesitan permisos de administrador para instalar.
- **Android:** Android 10 o superior.
- **Terminales cliente:** deben estar en la misma red que el servidor.

## Instalación

### Windows (servidor)

1. Descargue `LethorPos-Setup-v{version}.exe`.
2. Ejecútelo y siga los pasos del asistente. Incluye todo lo necesario, no hay que instalar nada más.
3. Abra LethorPos desde el acceso directo del escritorio o del menú Inicio.

### Actualizar en Windows

1. Descargue `LethorPos-Update-v{version}.exe`.
2. Ejecútelo. La información del negocio y la configuración se conservan.

El actualizador solo funciona en equipos que ya tienen LethorPos instalado; para una instalación nueva use
`LethorPos-Setup-v{version}.exe`.

### Android

1. Descargue el `.apk` desde el dispositivo.
2. Ábralo y, si Android lo solicita, permita instalar aplicaciones de esta fuente.
3. Para actualizar, instale el `.apk` de la versión nueva encima de la anterior; los datos se conservan.

## Verificar la descarga (opcional)

Cada versión incluye `SHA256SUMS.txt` con el código de verificación de cada archivo. En Windows puede
comprobarlo desde PowerShell:

```powershell
Get-FileHash .\LethorPos-Setup-v{version}.exe -Algorithm SHA256
```

El resultado debe coincidir con el valor que aparece en `SHA256SUMS.txt` para ese archivo.

## Soporte

Para dudas, licencias o soporte técnico visite [www.lethorsoft.com](http://www.lethorsoft.com).
