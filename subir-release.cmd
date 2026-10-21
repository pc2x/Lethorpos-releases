@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0subir-release.ps1" %*
set ERR=%ERRORLEVEL%
if %ERR% neq 0 (
  echo.
  echo ERROR: la subida fallo con codigo %ERR%. Vuelva a ejecutar para continuar donde se quedo.
)
pause
exit /b %ERR%
