#Requires -Version 5.1
<#
  Sube a GitHub Releases (pc2x/Lethorpos-releases) una version preparada en staging\v{version}\ por
  build-installer.ps1 del repo LethorPos. Los archivos se suben uno por uno con barra de progreso (curl).

  El release se crea como borrador y solo se publica al final, cuando ya estan todos los archivos. Si la subida
  se interrumpe, vuelva a ejecutar: los archivos que ya estan completos en GitHub (mismo SHA-256) se omiten.

  Parametros:
    -Version 1.0.149     Version a subir (tambien acepta 001.00.149). Por defecto la mas reciente de staging\.
    -Borrador            Deja el release como borrador para revisarlo en GitHub antes de publicarlo.
    -Limpiar             Borra staging\v{version}\ si la subida termina bien.

  Para ver que archivos ya estan en GitHub sin subir nada: estado-release.ps1 (o estado-release.cmd).

  Requisitos: GitHub CLI (winget install GitHub.cli) con sesion iniciada (gh auth login) en una cuenta con
  permiso de escritura en el repo, y curl.exe (incluido en Windows 10/11).
#>
param(
  [string]$Version,
  [switch]$Borrador,
  [switch]$Limpiar
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "comun-release.ps1")

Write-Host ""
Write-Host "LethorPos - Subir release a GitHub ($Repo)" -ForegroundColor Yellow

$version_padded = Resolve-VersionStaging $Version
$tag = "v$version_padded"
$StagingDir = Join-Path $StagingRoot $tag
$sumas = Join-Path $StagingDir "SHA256SUMS.txt"
$notas = Join-Path $StagingDir "notas.md"
foreach ($requerido in @($sumas, $notas)) {
  if (-not (Test-Path $requerido)) {
    throw "No existe $requerido. Ejecute build-installer.ps1 para preparar la version $version_padded."
  }
}

Write-Host ("Version: {0}{1}" -f $tag, $(if ($Borrador) { " (borrador)" } else { "" })) -ForegroundColor Yellow
Write-Host ("Origen:  {0}" -f $StagingDir) -ForegroundColor Yellow

Write-Step "Verificando SHA-256"
$archivos = @()
foreach ($linea in Get-Content $sumas) {
  if ($linea -notmatch '^([0-9a-f]{64})\s+(.+)$') {
    continue
  }
  $hash_esperado = $Matches[1]
  $archivo = Join-Path $StagingDir $Matches[2].Trim()
  if (-not (Test-Path $archivo)) {
    throw "Falta $archivo (listado en SHA256SUMS.txt)."
  }
  $hash = (Get-FileHash $archivo -Algorithm SHA256).Hash.ToLowerInvariant()
  if ($hash -ne $hash_esperado) {
    throw "El SHA-256 de $archivo no coincide con SHA256SUMS.txt (esperado $hash_esperado, obtenido $hash)."
  }
  Write-Host ("    OK  {0} ({1} MB)" -f (Split-Path $archivo -Leaf), (Get-Mb $archivo))
  $archivos += [pscustomobject]@{ Ruta = $archivo; Sha256 = $hash }
}
if (-not $archivos) {
  throw "SHA256SUMS.txt no lista ningun archivo."
}
# Primero los chicos: con una subida lenta, los clientes y APK quedan disponibles antes que el Setup.
$archivos = @($archivos | Sort-Object { (Get-Item $_.Ruta).Length })
$archivos += [pscustomobject]@{ Ruta = $sumas; Sha256 = (Get-FileHash $sumas -Algorithm SHA256).Hash.ToLowerInvariant() }

Write-Step "Comprobando GitHub CLI y curl"
Initialize-Gh
$curl = Get-Command "curl.exe" -ErrorAction SilentlyContinue
if (-not $curl) {
  throw "No se encontro curl.exe (viene con Windows 10 1803 o posterior)."
}
$token = (Invoke-GhSalida @("auth", "token")).Trim()
Write-Host "    Sesion de gh activa." -ForegroundColor Green

$release = Get-Release $tag
if ($release) {
  Write-Step "El release $tag ya existe: se completan los archivos que falten"
  if ((Invoke-Gh @("release", "edit", $tag, "--repo", $Repo, "--notes-file", $notas)) -ne 0) {
    throw "Fallo la actualizacion de las notas de $tag."
  }
}
else {
  Write-Step "Creando release $tag (borrador hasta terminar la subida)"
  $argumentos = @("release", "create", $tag, "--repo", $Repo, "--target", "main", "--draft",
    "--title", "LethorPos $tag", "--notes-file", $notas)
  if ((Invoke-Gh $argumentos) -ne 0) {
    throw "Fallo la creacion del release $tag."
  }
  $release = Get-Release $tag
}

$total = $archivos.Count
$indice = 0
$inicio = Get-Date
foreach ($archivo in $archivos) {
  $indice++
  $nombre = Split-Path $archivo.Ruta -Leaf
  Write-Step ("[{0}/{1}] {2} ({3} MB)" -f $indice, $total, $nombre, (Get-Mb $archivo.Ruta))

  $existente = $release.assets | Where-Object { $_.name -eq $nombre } | Select-Object -First 1
  if ($existente) {
    if ($existente.state -eq "uploaded" -and $existente.digest -eq "sha256:$($archivo.Sha256)") {
      Write-Host "    Ya esta en GitHub (mismo SHA-256); se omite." -ForegroundColor DarkGray
      continue
    }
    Write-Host "    En GitHub hay una version distinta o incompleta; se reemplaza." -ForegroundColor DarkYellow
    if ((Invoke-Gh @("api", "-X", "DELETE", $existente.apiUrl) -Silencioso) -ne 0) {
      throw "No se pudo borrar el archivo anterior $nombre del release."
    }
  }

  $url = "https://uploads.github.com/repos/{0}/releases/{1}/assets?name={2}" -f $Repo, $release.databaseId,
    [Uri]::EscapeDataString($nombre)
  $inicio_archivo = Get-Date
  # Sin redireccion, curl dibuja en la consola su medidor: porcentaje, velocidad y tiempo restante.
  & $curl.Source --fail --show-error -o NUL -X POST `
    -H "Authorization: Bearer $token" -H "Accept: application/vnd.github+json" `
    -H "Content-Type: application/octet-stream" -T $archivo.Ruta $url
  if ($LASTEXITCODE -ne 0) {
    throw "Fallo la subida de $nombre (curl codigo $LASTEXITCODE). Vuelva a ejecutar para continuar donde se quedo."
  }
  $segundos = [math]::Max(1, ((Get-Date) - $inicio_archivo).TotalSeconds)
  Write-Host ("    Subido en {0:hh\:mm\:ss} ({1:N0} KB/s)." -f [TimeSpan]::FromSeconds($segundos),
    ((Get-Item $archivo.Ruta).Length / 1KB / $segundos)) -ForegroundColor Green
}

if (-not $Borrador) {
  Write-Step "Publicando release $tag"
  if ((Invoke-Gh @("release", "edit", $tag, "--repo", $Repo, "--draft=false", "--latest")) -ne 0) {
    throw "Los archivos estan subidos pero fallo la publicacion. Publiquelo en https://github.com/$Repo/releases"
  }
}

Write-Host ""
Write-Host ("Release {0} {1} en {2:hh\:mm\:ss}." -f $tag, $(if ($Borrador) { "subido como borrador" } else { "publicado" }),
  ((Get-Date) - $inicio)) -ForegroundColor Green
if ($Borrador) {
  Write-Host "  Publiquelo en https://github.com/$Repo/releases (Edit > Publish release) o con:" -ForegroundColor DarkYellow
  Write-Host "  gh release edit $tag --repo $Repo --draft=false --latest" -ForegroundColor DarkYellow
}
else {
  foreach ($archivo in $archivos) {
    Write-Host ("  https://github.com/{0}/releases/download/{1}/{2}" -f $Repo, $tag, (Split-Path $archivo.Ruta -Leaf))
  }
}
Write-Host ""

if ($Limpiar) {
  Remove-Item $StagingDir -Recurse -Force
  Write-Host "    Se borro $StagingDir." -ForegroundColor DarkGray
}
