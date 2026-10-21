@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0estado-release.ps1" -Seguir %*
exit /b %ERRORLEVEL%
