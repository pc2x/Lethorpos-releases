#Requires -Version 5.1
<#
  Muestra que archivos de una version ya estan completos en GitHub y cuales faltan, sin subir nada.
  GitHub solo lista un archivo cuando termino de subirse; el avance del archivo en curso se ve en la
  ventana de subir-release.

  Parametros:
    -Version 1.0.149     Version a revisar. Por defecto la mas reciente de staging\.
    -Seguir              Repite la consulta cada 30 segundos (Ctrl+C para salir) y muestra la velocidad de subida.
#>
param(
  [string]$Version,
  [switch]$Seguir
)

$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "comun-release.ps1")

function Get-BytesEnviados {
  return (Get-NetAdapterStatistics -ErrorAction SilentlyContinue | Measure-Object SentBytes -Sum).Sum
}

function Show-Estado([string]$Tag, [string]$StagingDir) {
  $release = Get-Release $Tag
  Write-Host ""
  Write-Host ("LethorPos {0} - {1}" -f $Tag, (Get-Date).ToString("HH:mm:ss")) -ForegroundColor Yellow
  if (-not $release) {
    Write-Host "    El release no existe todavia en GitHub." -ForegroundColor DarkYellow
  }
  else {
    Write-Host ("    {0}: {1}" -f $(if ($release.isDraft) { "Borrador" } else { "Publicado" }), $release.url) -ForegroundColor DarkGray
  }

  $locales = @()
  if (Test-Path $StagingDir) {
    $locales = Get-ChildItem -Path $StagingDir -File | Where-Object { $_.Name -ne "notas.md" }
  }
  $remotos = if ($release) { @($release.assets) } else { @() }
  $nombres = @($locales | ForEach-Object Name) + @($remotos | ForEach-Object name) | Sort-Object -Unique

  $completos = 0
  $filas = foreach ($nombre in $nombres) {
    $local = $locales | Where-Object Name -eq $nombre | Select-Object -First 1
    $remoto = $remotos | Where-Object name -eq $nombre | Select-Object -First 1
    $estado = if (-not $remoto) { "Falta" }
      elseif ($remoto.state -ne "uploaded") { "Incompleto" }
      elseif ($local -and $remoto.size -ne $local.Length) { "Distinto" }
      else { $completos++; "Completo" }
    [pscustomobject]@{
      Archivo = $nombre
      MB      = if ($local) { [math]::Round($local.Length / 1MB, 1) } else { [math]::Round($remoto.size / 1MB, 1) }
      GitHub  = $estado
    }
  }
  $filas | Format-Table -AutoSize | Out-Host
  Write-Host ("    {0} de {1} archivos completos en GitHub." -f $completos, @($nombres).Count)
}

$version_padded = Resolve-VersionStaging $Version
$tag = "v$version_padded"
$staging_dir = Join-Path $StagingRoot $tag
Initialize-Gh

if (-not $Seguir) {
  Show-Estado $tag $staging_dir
  return
}

$bytes_previos = Get-BytesEnviados
$momento_previo = Get-Date
while ($true) {
  Clear-Host
  Show-Estado $tag $staging_dir
  $bytes = Get-BytesEnviados
  $ahora = Get-Date
  $kbs = ($bytes - $bytes_previos) / 1KB / [math]::Max(1, ($ahora - $momento_previo).TotalSeconds)
  Write-Host ("    Subida de la red: {0:N0} KB/s. Siguiente consulta en 30 s (Ctrl+C para salir)." -f $kbs) -ForegroundColor DarkGray
  $bytes_previos = $bytes
  $momento_previo = $ahora
  Start-Sleep -Seconds 30
}
