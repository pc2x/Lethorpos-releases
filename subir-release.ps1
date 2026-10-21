#Requires -Version 5.1
<#
  Sube a GitHub Releases (pc2x/Lethorpos-releases) una version preparada en staging\v{version}\ por
  build-installer.ps1 del repo LethorPos. Crea el release v{version} o, si ya existe, reemplaza sus archivos
  (sirve para reintentar una subida interrumpida).

  Parametros:
    -Version 1.0.149     Version a subir (tambien acepta 001.00.149). Por defecto la mas reciente de staging\.
    -Borrador            Crea el release como borrador para revisarlo en GitHub antes de publicarlo.
    -Limpiar             Borra staging\v{version}\ si la subida termina bien.

  Requisitos: GitHub CLI (winget install GitHub.cli) con sesion iniciada (gh auth login) en una cuenta con
  permiso de escritura en el repo.
#>
param(
  [string]$Version,
  [switch]$Borrador,
  [switch]$Limpiar
)

$ErrorActionPreference = "Stop"

$Repo = "pc2x/Lethorpos-releases"
$StagingRoot = Join-Path $PSScriptRoot "staging"

function Write-Step([string]$Message) {
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-VersionPadded([string]$Raw) {
  $v = $Raw.Trim().TrimStart("v", "V")
  if ($v -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
    throw "Formato de version invalido: '$Raw'. Use por ejemplo 1.0.149 o 001.00.149."
  }
  return "{0:D3}.{1:D2}.{2:D3}" -f [int]$Matches[1], [int]$Matches[2], [int]$Matches[3]
}

function Find-Gh {
  $comando = Get-Command "gh" -ErrorAction SilentlyContinue
  if ($comando) {
    return $comando.Source
  }

  # winget no refresca el PATH de la consola en la que se instalo.
  foreach ($candidato in @((Join-Path $env:ProgramFiles "GitHub CLI\gh.exe"), (Join-Path $env:LOCALAPPDATA "Programs\GitHub CLI\gh.exe"))) {
    if (Test-Path $candidato) {
      return $candidato
    }
  }

  throw "No se encontro GitHub CLI. Instalelo con: winget install GitHub.cli  y luego: gh auth login"
}

# Con ErrorActionPreference = Stop, PowerShell 5.1 convierte el stderr redirigido de un ejecutable en excepcion.
function Invoke-Gh([string[]]$Argumentos, [switch]$Silencioso) {
  $ErrorActionPreference = "Continue"
  if ($Silencioso) {
    & $script:Gh @Argumentos *> $null
  }
  else {
    & $script:Gh @Argumentos | Out-Host
  }
  return $LASTEXITCODE
}

Write-Host ""
Write-Host "LethorPos - Subir release a GitHub ($Repo)" -ForegroundColor Yellow

if ($Version) {
  $version_padded = Get-VersionPadded $Version
}
else {
  $ultima = Get-ChildItem -Path $StagingRoot -Directory -Filter "v*" -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    Select-Object -First 1
  if (-not $ultima) {
    throw "No hay versiones en $StagingRoot. Ejecute build-installer.ps1 en el repo LethorPos."
  }
  $version_padded = Get-VersionPadded $ultima.Name
}

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
  Write-Host ("    OK  {0} ({1} MB)" -f (Split-Path $archivo -Leaf), [math]::Round((Get-Item $archivo).Length / 1MB, 1))
  $archivos += $archivo
}
if (-not $archivos) {
  throw "SHA256SUMS.txt no lista ningun archivo."
}
$archivos += $sumas

Write-Step "Comprobando GitHub CLI"
$script:Gh = Find-Gh
if ((Invoke-Gh @("auth", "status") -Silencioso) -ne 0) {
  throw "GitHub CLI no tiene sesion iniciada. Ejecute: gh auth login"
}
Write-Host "    Sesion de gh activa." -ForegroundColor Green

if ((Invoke-Gh @("release", "view", $tag, "--repo", $Repo) -Silencioso) -eq 0) {
  Write-Step "El release $tag ya existe: reemplazando archivos y notas"
  if ((Invoke-Gh (@("release", "upload", $tag, "--repo", $Repo, "--clobber") + $archivos)) -ne 0) {
    throw "Fallo la subida de archivos a $tag. Puede reintentar: se reemplazan los que ya esten."
  }
  if ((Invoke-Gh @("release", "edit", $tag, "--repo", $Repo, "--notes-file", $notas)) -ne 0) {
    throw "Fallo la actualizacion de las notas de $tag."
  }
}
else {
  Write-Step "Creando release $tag y subiendo archivos"
  $argumentos = @("release", "create", $tag, "--repo", $Repo, "--target", "main",
    "--title", "LethorPos $tag", "--notes-file", $notas)
  $argumentos += if ($Borrador) { "--draft" } else { "--latest" }
  if ((Invoke-Gh ($argumentos + $archivos)) -ne 0) {
    throw "Fallo la creacion de $tag. Si el release quedo creado a medias, vuelva a ejecutar: se completaran los archivos."
  }
}

Write-Host ""
Write-Host "Release $tag subido." -ForegroundColor Green
if ($Borrador) {
  Write-Host "  Es borrador: publiquelo en https://github.com/$Repo/releases para habilitar las descargas." -ForegroundColor DarkYellow
}
foreach ($archivo in $archivos) {
  Write-Host ("  https://github.com/{0}/releases/download/{1}/{2}" -f $Repo, $tag, (Split-Path $archivo -Leaf))
}
Write-Host ""

if ($Limpiar) {
  Remove-Item $StagingDir -Recurse -Force
  Write-Host "    Se borro $StagingDir." -ForegroundColor DarkGray
}
