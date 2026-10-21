# Funciones compartidas por subir-release.ps1 y estado-release.ps1 (se cargan con dot-source).

$Repo = "pc2x/Lethorpos-releases"
$StagingRoot = Join-Path $PSScriptRoot "staging"

function Write-Step([string]$Message) {
  Write-Host ""
  Write-Host "==> $Message" -ForegroundColor Cyan
}

function Get-Mb([string]$Ruta) {
  return [math]::Round((Get-Item $Ruta).Length / 1MB, 1)
}

function Get-VersionPadded([string]$Raw) {
  $v = $Raw.Trim().TrimStart("v", "V")
  if ($v -notmatch '^(\d+)\.(\d+)\.(\d+)$') {
    throw "Formato de version invalido: '$Raw'. Use por ejemplo 1.0.149 o 001.00.149."
  }
  return "{0:D3}.{1:D2}.{2:D3}" -f [int]$Matches[1], [int]$Matches[2], [int]$Matches[3]
}

# Sin version explicita toma la mas reciente de staging\ (el nombre con relleno ordena bien como texto).
function Resolve-VersionStaging([string]$Version) {
  if ($Version) {
    return Get-VersionPadded $Version
  }

  $ultima = Get-ChildItem -Path $StagingRoot -Directory -Filter "v*" -ErrorAction SilentlyContinue |
    Sort-Object Name -Descending |
    Select-Object -First 1
  if (-not $ultima) {
    throw "No hay versiones en $StagingRoot. Ejecute build-installer.ps1 en el repo LethorPos."
  }
  return Get-VersionPadded $ultima.Name
}

function Initialize-Gh {
  $comando = Get-Command "gh" -ErrorAction SilentlyContinue
  $script:Gh = if ($comando) { $comando.Source } else { $null }

  # winget no refresca el PATH de la consola en la que se instalo.
  if (-not $script:Gh) {
    foreach ($candidato in @((Join-Path $env:ProgramFiles "GitHub CLI\gh.exe"), (Join-Path $env:LOCALAPPDATA "Programs\GitHub CLI\gh.exe"))) {
      if (Test-Path $candidato) {
        $script:Gh = $candidato
        break
      }
    }
  }
  if (-not $script:Gh) {
    throw "No se encontro GitHub CLI. Instalelo con: winget install GitHub.cli  y luego: gh auth login"
  }

  if ((Invoke-Gh @("auth", "status") -Silencioso) -ne 0) {
    throw "GitHub CLI no tiene sesion iniciada. Ejecute: gh auth login"
  }
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

function Invoke-GhSalida([string[]]$Argumentos) {
  $ErrorActionPreference = "Continue"
  $salida = & $script:Gh @Argumentos 2> $null
  if ($LASTEXITCODE -ne 0) {
    throw "Fallo: gh $($Argumentos -join ' ')"
  }
  return ($salida -join "`n")
}

# Devuelve el release (incluidos borradores) con sus archivos, o $null si no existe.
function Get-Release([string]$Tag) {
  $ErrorActionPreference = "Continue"
  $salida = & $script:Gh release view $Tag --repo $Repo --json "databaseId,isDraft,url,assets" 2> $null
  if ($LASTEXITCODE -ne 0) {
    return $null
  }
  return ($salida -join "`n") | ConvertFrom-Json
}
