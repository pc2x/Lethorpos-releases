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
3. Ejecutar `subir-release.ps1` (toma la versión más reciente de `staging\`) o `subir-release.ps1 -Version 1.0.149`.
   Con `-Borrador` crea el release como borrador para revisarlo antes de publicarlo.

Requisitos de una sola vez: `winget install GitHub.cli` y `gh auth login` con una cuenta con permiso de
escritura en `pc2x/Lethorpos-releases`.
