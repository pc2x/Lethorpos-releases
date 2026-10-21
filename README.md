# LethorPos - Releases

Descargas públicas de LethorPos para Windows y Android.

**Última versión:** https://github.com/pc2x/Lethorpos-releases/releases/latest

## Archivos de cada release

| Archivo | Qué es |
| --- | --- |
| `LethorPos-Setup-v{version}.exe` | Instalador completo para Windows: aplicación, cliente ligero, PostgreSQL portable y dependencias. Para instalaciones nuevas. |
| `LethorPos-Update-v{version}.exe` | Actualizador para Windows: solo la aplicación y el cliente ligero. Requiere una instalación previa con el instalador completo. |
| `LethorPos-Android-v{version}.apk` | APK de Android con servidor incluido. |
| `LethorPos-Cliente-Windows-v{version}.exe` | Cliente ligero para Windows (se conecta a un servidor LethorPos). |
| `LethorPos-Cliente-Android-v{version}.apk` | Cliente ligero para Android (se conecta a un servidor LethorPos). |
| `SHA256SUMS.txt` | Hashes SHA-256 para verificar las descargas. |

## Publicar una versión

1. En el repo `LethorPos`, ejecutar `build-installer.ps1`. Al terminar deja los archivos listos en
   `staging\v{version}\` de este repo (nombres estables, `SHA256SUMS.txt` y `notas.md`).
2. Opcional: editar `staging\v{version}\notas.md` con los cambios de la versión.
3. Doble clic en `subir-release.cmd` (o `subir-release.ps1 -Version 1.0.149` para una versión específica).
   Sube archivo por archivo con barra de progreso (porcentaje, velocidad y tiempo restante) y publica el release
   al terminar. Con `-Borrador` lo deja como borrador para revisarlo antes de publicarlo.
   Si la subida se corta, vuelva a ejecutarlo: los archivos que ya están completos en GitHub se omiten.
4. Para ver qué archivos ya están en GitHub y cuáles faltan, doble clic en `estado-release.cmd`
   (se actualiza cada 30 segundos; Ctrl+C para salir).

Requisitos de una sola vez: `winget install GitHub.cli` y `gh auth login` con una cuenta con permiso de
escritura en `pc2x/Lethorpos-releases`.
